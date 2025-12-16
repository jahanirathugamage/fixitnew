// functions/src/index.ts

import * as functionsModule from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import * as nodemailer from "nodemailer";

// We’ll use `functions` as `any` to avoid v1/v2 typing conflicts.
const functions: any = functionsModule;

admin.initializeApp();

// ---------------------------------------------------------------------
// SMTP / nodemailer config
// ---------------------------------------------------------------------

interface SmtpConfig {
  user?: string;
  pass?: string;
}

// Use functions.config() but through `any` to avoid "not callable" errors
const runtimeConfig = functions.config ? functions.config() : {};
const smtpConfig: SmtpConfig = (runtimeConfig.smtp || {}) as SmtpConfig;

const smtpUser = smtpConfig.user;
const smtpPass = smtpConfig.pass;

if (!smtpUser || !smtpPass) {
  console.warn(
    "SMTP config is missing! Run: " +
      'firebase functions:config:set smtp.user="YOUR_EMAIL" ' +
      'smtp.pass="YOUR_APP_PASSWORD"',
  );
}

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: smtpUser,
    pass: smtpPass,
  },
});

// Helper to send email
async function sendEmail(to: string, subject: string, text: string): Promise<void> {
  if (!smtpUser || !smtpPass) {
    console.warn("sendEmail called but SMTP config is missing.");
    return;
  }

  console.log("Sending email to:", to, "subject:", subject);

  await transporter.sendMail({
    from: `"FixIt Admin" <${smtpUser}>`,
    to,
    subject,
    text,
  });

  console.log("Email sent to:", to);
}

// ---------------------------------------------------------------------
// 1) createAdminInvite (callable) – existing admin invites a new admin
// ---------------------------------------------------------------------

interface AdminInviteData {
  firstName?: string;
  lastName?: string;
  email?: string;
}

export const createAdminInvite = functions.https.onCall(
  async (data: AdminInviteData, context: any) => {
    if (!context.auth) {
      throw new functionsModule.https.HttpsError(
        "unauthenticated",
        "You must be logged in.",
      );
    }

    const callerUid = context.auth.uid;

    const userDoc = await admin.firestore().collection("users").doc(callerUid).get();

    if (!userDoc.exists || userDoc.data()?.role !== "admin") {
      throw new functionsModule.https.HttpsError(
        "permission-denied",
        "Only admins can create other admins.",
      );
    }

    const firstName = (data.firstName || "").trim();
    const lastName = (data.lastName || "").trim();
    const email = (data.email || "").trim();

    if (!firstName || !lastName || !email || !email.includes("@")) {
      throw new functionsModule.https.HttpsError(
        "invalid-argument",
        "Invalid name or email.",
      );
    }

    const token = crypto.randomBytes(32).toString("hex");

    const inviteRef = admin.firestore().collection("adminInvites").doc(token);
    await inviteRef.set({
      firstName,
      lastName,
      email,
      createdBy: callerUid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "pending",
    });

    // TODO: replace with your real domain / hosting URL
    const approvalLink = `https://YOUR_DOMAIN/admin-approve?token=${token}`;

    const text =
      `Hi ${firstName},\n\n` +
      "You have been invited to become an administrator at FixIt.\n\n" +
      "Please click the link below to approve and activate your " +
      "admin account:\n\n" +
      `${approvalLink}\n\n` +
      "If you did not expect this invite, you can ignore this email.\n";

    await sendEmail(email, "FixIt admin approval link", text);

    return { ok: true };
  },
);

// ---------------------------------------------------------------------
// 2) handleAdminApproval (HTTP) – user clicks email link, account created
// ---------------------------------------------------------------------

export const handleAdminApproval = functions.https.onRequest(
  async (req: any, res: any) => {
    const tokenParam = req.query.token;
    const token =
      typeof tokenParam === "string" ? tokenParam : String(tokenParam || "");

    if (!token) {
      res.status(400).send("Missing or invalid token.");
      return;
    }

    const inviteRef = admin.firestore().collection("adminInvites").doc(token);
    const snap = await inviteRef.get();

    if (!snap.exists) {
      res.status(400).send("Invalid or expired invitation.");
      return;
    }

    const data = snap.data() || {};
    if (data.status === "approved") {
      res.send("This invitation has already been approved.");
      return;
    }

    const firstName = (data.firstName as string) || "";
    const lastName = (data.lastName as string) || "";
    const email = (data.email as string) || "";

    const password = crypto.randomBytes(9).toString("base64").slice(0, 12);

    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: `${firstName} ${lastName}`,
    });

    await admin.firestore().collection("users").doc(userRecord.uid).set({
      role: "admin",
      firstName,
      lastName,
      email,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await admin.firestore().collection("admins").doc(userRecord.uid).set({
      firstName,
      lastName,
      email,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await inviteRef.update({
      status: "approved",
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      adminUid: userRecord.uid,
    });

    const text =
      `Hi ${firstName},\n\n` +
      "Your admin account has been approved.\n\n" +
      "You can now log in with:\n\n" +
      `Email: ${email}\n` +
      `Password: ${password}\n\n` +
      "For security, please log in and change your password immediately.\n\n" +
      "– FixIt Team";

    await sendEmail(email, "Your FixIt admin account", text);

    res.send(
      "Your admin account has been created. Please check your email for login details.",
    );
  },
);

// ---------------------------------------------------------------------
// 3) onContractorStatusChange – send rejection email when status=rejected
// ---------------------------------------------------------------------

export const onContractorStatusChange = functions.firestore
  .document("contractors/{contractorId}")
  .onUpdate(async (change: any, context: any) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};

    const prevStatus =
      (before.approvalStatus as string) || (before.status as string) || "pending";
    const newStatus =
      (after.approvalStatus as string) || (after.status as string) || "pending";

    if (prevStatus === "pending" && newStatus === "rejected") {
      const contractorId = context.params.contractorId as string;

      let email: string | null = (after.companyEmail as string | undefined) || null;

      if (!email) {
        const userSnap = await admin.firestore().collection("users").doc(contractorId).get();
        if (userSnap.exists) {
          email = (userSnap.data()?.email as string | undefined) || null;
        }
      }

      if (!email) {
        console.log("No email found for contractor", contractorId);
        return null;
      }

      const companyName = (after.companyName as string | undefined) || "your firm";
      const rawReason = (after.rejectionReason as string | undefined) || "";
      const cleanReason =
        rawReason && rawReason.trim() !== ""
          ? rawReason
          : "No specific reason was provided.";

      const subject = "Your FixIt contractor registration was rejected";
      const text =
        "Hello,\n\n" +
        "We’re sorry to inform you that your contractor registration " +
        `for "${companyName}" has been rejected.\n\n` +
        "Reason:\n" +
        `${cleanReason}\n\n` +
        "You may re-apply after addressing the above issues.\n\n" +
        "– FixIt Team";

      try {
        await sendEmail(email, subject, text);
        console.log("Rejection email sent to", email);
      } catch (err) {
        console.error("Failed to send rejection email:", err);
      }
    }

    return null;
  });

// ---------------------------------------------------------------------
// 4) createProviderAccount (callable) – contractor creates provider user
// ---------------------------------------------------------------------

interface ProviderAccountData {
  email?: string;
  password?: string;
  firstName?: string;
  lastName?: string;
  providerDocId?: string;
}

export const createProviderAccount = functions.https.onCall(
  async (data: ProviderAccountData, context: any) => {
    if (!context.auth) {
      throw new functionsModule.https.HttpsError(
        "unauthenticated",
        "You must be logged in.",
      );
    }

    const callerUid = context.auth.uid;

    const userSnap = await admin.firestore().collection("users").doc(callerUid).get();
    const role = userSnap.exists ? (userSnap.data()?.role as string) : null;

    if (role !== "contractor") {
      throw new functionsModule.https.HttpsError(
        "permission-denied",
        "Only contractors can create provider accounts.",
      );
    }

    const email = (data.email || "").trim();
    const password = (data.password || "").trim();
    const firstName = (data.firstName || "").trim();
    const lastName = (data.lastName || "").trim();
    const providerDocId = (data.providerDocId || "").trim();

    if (!email || !email.includes("@")) {
      throw new functionsModule.https.HttpsError("invalid-argument", "Invalid email.");
    }
    if (!password || password.length < 6) {
      throw new functionsModule.https.HttpsError(
        "invalid-argument",
        "Password must be at least 6 characters.",
      );
    }

    try {
      const userRecord = await admin.auth().createUser({
        email,
        password,
        displayName: `${firstName} ${lastName}`.trim() || undefined,
      });

      await admin.firestore().collection("users").doc(userRecord.uid).set(
        {
          role: "provider",
          firstName,
          lastName,
          email,
          contractorId: callerUid,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      if (providerDocId) {
        await admin.firestore()
          .collection("contractors")
          .doc(callerUid)
          .collection("providers")
          .doc(providerDocId)
          .set({ providerUid: userRecord.uid }, { merge: true });
      }

      try {
        const subject = "Your FixIt provider account";
        const text =
          `Hi ${firstName || ""},\n\n` +
          "A FixIt contractor has registered you as a service provider.\n\n" +
          "You can now log in with:\n\n" +
          `Email: ${email}\n` +
          `Password: ${password}\n\n` +
          "For security, please change your password after first sign in.\n\n" +
          "– FixIt Team";

        await sendEmail(email, subject, text);
      } catch (mailErr) {
        console.error("Email sending failed:", mailErr);
      }

      return { ok: true, providerUid: userRecord.uid };
    } catch (err: any) {
      console.error("createProviderAccount error:", err);

      const code = err?.code || "";
      if (code === "auth/email-already-exists") {
        throw new functionsModule.https.HttpsError(
          "already-exists",
          "A provider with this email already exists.",
        );
      }

      throw new functionsModule.https.HttpsError(
        "internal",
        err?.message || "Failed to create provider account.",
      );
    }
  },
);
