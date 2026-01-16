  // lib/backend/provider_api.dart

  import 'package:fixitnew/backend/api_client.dart';

  class ProviderApi {
    static Future<void> createProviderAccount({
      required String email,
      required String password,
      required String firstName,
      required String lastName,
      required String providerDocId,
    }) async {
      await ApiClient.postJson(
        "/api/create-provider-account",
        body: {
          "email": email,
          "password": password,
          "firstName": firstName,
          "lastName": lastName,
          "providerDocId": providerDocId,
        },
      );
    }
  }
