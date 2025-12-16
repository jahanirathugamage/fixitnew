// functions/src/index.ts

import * as functionsModule from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import * as nodemailer from "nodemailer";

// We’ll use `functionsAny` as `any` to avoid v1/v2 typing conflicts.
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
async function sendEmail(
  to: string,
  subject: string,
  text: string,
): Promise<void> {
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
    // Must be logged in
    if (!context.auth) {
      throw new functionsModule.https.HttpsError(
        "unauthenticated",
        "You must be logged in.",
      );
    }

    const callerUid = context.auth.uid;

    // Check caller is admin
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(callerUid)
      .get();

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

    // Random token for approval link
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

    return {ok: true};
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

    // Random initial password
    const password = crypto.randomBytes(9).toString("base64").slice(0, 12);

    // Create auth user
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: `${firstName} ${lastName}`,
    });

    // users/{uid}
    await admin
      .firestore()
      .collection("users")
      .doc(userRecord.uid)
      .set({
        role: "admin",
        firstName,
        lastName,
        email,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // admins/{uid} (optional)
    await admin
      .firestore()
      .collection("admins")
      .doc(userRecord.uid)
      .set({
        firstName,
        lastName,
        email,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // Mark invite as approved
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
      "For security, please log in and change your password " +
      "immediately.\n\n" +
      "– FixIt Team";

    await sendEmail(email, "Your FixIt admin account", text);

    res.send(
      "Your admin account has been created. " +
        "Please check your email for login details.",
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
      (before.approvalStatus as string) ||
      (before.status as string) ||
      "pending";
    const newStatus =
      (after.approvalStatus as string) ||
      (after.status as string) ||
      "pending";

    // Only care about pending -> rejected
    if (prevStatus === "pending" && newStatus === "rejected") {
      const contractorId = context.params.contractorId as string;

      // 1) Try companyEmail on contractor doc
      let email: string | null =
        (after.companyEmail as string | undefined) || null;

      // 2) Fallback to users/{contractorId}.email
      if (!email) {
        const userSnap = await admin
          .firestore()
          .collection("users")
          .doc(contractorId)
          .get();
        if (userSnap.exists) {
          email = (userSnap.data()?.email as string | undefined) || null;
        }
      }

      if (!email) {
        console.log("No email found for contractor", contractorId);
        return null;
      }

      const companyName =
        (after.companyName as string | undefined) || "your firm";
      const rawReason =
        (after.rejectionReason as string | undefined) || "";
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

    // Caller must be contractor
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
      throw new functionsModule.https.HttpsError("invalid-argument", "Password must be at least 6 characters.");
    }

    try {
      // Create auth user
      const userRecord = await admin.auth().createUser({
        email,
        password,
        displayName: `${firstName} ${lastName}`.trim() || undefined,
      });

      // users/{uid} with role=provider
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

      // Link to contractors/{callerUid}/providers/{providerDocId}
      if (providerDocId) {
        await admin.firestore()
          .collection("contractors")
          .doc(callerUid)
          .collection("providers")
          .doc(providerDocId)
          .set({ providerUid: userRecord.uid }, { merge: true });
      }

      // Email (optional)
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
        // Don't fail account creation just because email failed
      }

      // ✅ return providerUid so your app can use it immediately if you want
      return { ok: true, providerUid: userRecord.uid };
    } catch (err: any) {
      console.error("createProviderAccount error:", err);

      // ✅ surface common Auth errors clearly
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


// ---------------------------------------------------------------------
// 5) Mirror provider docs into a top-level directory for fast querying
// ---------------------------------------------------------------------

// type ProviderMirror = {
//   providerUid?: string | null;
//   contractorId: string;
//   providerDocId: string;

//   firstName?: string;
//   lastName?: string;
//   email?: string;
//   phone?: string;

//   address?: {
//     address1?: string;
//     address2?: string;
//     city?: string;
//   };

//   languages?: string[];
//   categories?: string[];

//   // Useful matching fields (optional / future)
//   cancellationRate?: number; // default 0
//   isActive?: boolean;        // default true
//   updatedAt: FirebaseFirestore.FieldValue;
//   createdAt?: FirebaseFirestore.FieldValue;
// };

// function mirrorDocId(contractorId: string, providerDocId: string, providerUid?: string) {
//   // Prefer providerUid when available, so provider is unique globally.
//   // Fallback to a stable composite id until providerUid exists.
//   return (providerUid && providerUid.trim() !== "")
//     ? providerUid
//     : `${contractorId}_${providerDocId}`;
// }

// // CREATE / UPDATE mirror (runs on create + update)
// export const mirrorProviderToDirectory = functions.firestore
//   .document("contractors/{contractorId}/providers/{providerDocId}")
//   .onWrite(async (change: any, context: any) => {
//     const contractorId = String(context.params.contractorId);
//     const providerDocId = String(context.params.providerDocId);

//     // If deleted -> delete mirror too
//     if (!change.after.exists) {
//       // We don't know providerUid reliably at delete time unless it was stored,
//       // so delete both possible ids safely.
//       const before = change.before.data() || {};
//       const providerUid = (before.providerUid as string | undefined) || "";
//       const id1 = mirrorDocId(contractorId, providerDocId, providerUid);
//       const id2 = `${contractorId}_${providerDocId}`;

//       await admin.firestore().collection("providerDirectory").doc(id1).delete().catch(() => {});
//       if (id2 !== id1) {
//         await admin.firestore().collection("providerDirectory").doc(id2).delete().catch(() => {});
//       }
//       return null;
//     }

//     const data = change.after.data() || {};
//     const providerUid = (data.providerUid as string | undefined) || "";

//     const docId = mirrorDocId(contractorId, providerDocId, providerUid);

//     const mirror: ProviderMirror = {
//       providerUid: providerUid || null,
//       contractorId,
//       providerDocId,

//       firstName: data.firstName || "",
//       lastName: data.lastName || "",
//       email: data.email || "",
//       phone: data.phone || "",

//       address: {
//         address1: data.address1 || "",
//         address2: data.address2 || "",
//         city: data.city || "",
//       },

//       languages: Array.isArray(data.languages) ? data.languages : [],
//       categories: Array.isArray(data.categories) ? data.categories : [],

//       // optional matching fields
//       cancellationRate: typeof data.cancellationRate === "number" ? data.cancellationRate : 0,
//       isActive: typeof data.isActive === "boolean" ? data.isActive : true,

//       updatedAt: admin.firestore.FieldValue.serverTimestamp(),
//     };

//     // If mirror doc was newly created, set createdAt once (best-effort)
//     const mirrorRef = admin.firestore().collection("providerDirectory").doc(docId);
//     const existing = await mirrorRef.get();
//     if (!existing.exists) {
//       mirror.createdAt = admin.firestore.FieldValue.serverTimestamp();
//     }

//     await mirrorRef.set(mirror, { merge: true });

//     // If providerUid exists now, also remove the old composite mirror id (cleanup)
//     if (providerUid) {
//       const compositeId = `${contractorId}_${providerDocId}`;
//       if (compositeId !== docId) {
//         await admin.firestore().collection("providerDirectory").doc(compositeId).delete().catch(() => {});
//       }
//     }

//     return null;
//   });
