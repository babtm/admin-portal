// Dart imports:
import 'dart:convert';
import 'dart:core';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:built_collection/built_collection.dart';
import 'package:http/http.dart';

// Project imports:
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/data/models/serializers.dart';
import 'package:invoiceninja_flutter/data/web_client.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/utils/serialization.dart';

class ClientRepository {
  const ClientRepository({
    this.webClient = const WebClient(),
  });

  final WebClient webClient;

  Future<ClientEntity> loadItem(
      Credentials credentials, String entityId) async {
    final String url =
        '${credentials.url}/clients/$entityId?include=gateway_tokens,activities,ledger,system_logs,documents';

    final dynamic response = await webClient.get(url, credentials.token);

    final ClientItemResponse clientResponse = await compute<dynamic, dynamic>(
        SerializationUtils.computeDecode,
        <dynamic>[ClientItemResponse.serializer, response]);

    return clientResponse.data;
  }

  Future<BuiltList<ClientEntity>> loadList(Credentials credentials) async {
    final String url = credentials.url + '/clients?';

    final dynamic response = await webClient.get(url, credentials.token);

    final ClientListResponse clientResponse = await compute<dynamic, dynamic>(
        SerializationUtils.computeDecode,
        <dynamic>[ClientListResponse.serializer, response]);

    return clientResponse.data;
  }

  Future<List<ClientEntity>> bulkAction(
      Credentials credentials, List<String> ids, EntityAction action) async {
    if (ids.length > kMaxEntitiesPerBulkAction) {
      ids = ids.sublist(0, kMaxEntitiesPerBulkAction);
    }

    final url = credentials.url +
        '/clients/bulk?include=gateway_tokens,activities,ledger,system_logs,documents';
    final dynamic response = await webClient.post(url, credentials.token,
        data: json.encode({'ids': ids, 'action': action.toApiParam()}));

    final ClientListResponse clientResponse =
        serializers.deserializeWith(ClientListResponse.serializer, response);

    return clientResponse.data.toList();
  }

  Future<bool> purge(Credentials credentials, String id) async {
    final url = credentials.url + '/clients/$id/purge';

    await webClient.post(url, credentials.token);

    return true;
  }

  Future<ClientEntity> saveData(
      Credentials credentials, ClientEntity client) async {
    client = client.rebuild((b) => b..documents.clear());
    final data = serializers.serializeWith(ClientEntity.serializer, client);
    dynamic response;

    if (client.isNew) {
      response = await webClient.post(
          credentials.url +
              '/clients?include=gateway_tokens,activities,ledger,system_logs,documents',
          credentials.token,
          data: json.encode(data));
    } else {
      final url = credentials.url +
          '/clients/${client.id}?include=gateway_tokens,activities,ledger,system_logs,documents';
      response =
          await webClient.put(url, credentials.token, data: json.encode(data));
    }

    final ClientItemResponse clientResponse =
        serializers.deserializeWith(ClientItemResponse.serializer, response);

    return clientResponse.data;
  }

  Future<ClientEntity> uploadDocument(Credentials credentials,
      BaseEntity entity, MultipartFile multipartFile) async {
    final fields = <String, String>{
      '_method': 'put',
    };

    final dynamic response = await webClient.post(
        '${credentials.url}/clients/${entity.id}/upload', credentials.token,
        data: fields, multipartFiles: [multipartFile]);

    final ClientItemResponse clientResponse =
        serializers.deserializeWith(ClientItemResponse.serializer, response);

    return clientResponse.data;
  }
}
