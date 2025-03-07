// Flutter imports:
import 'dart:async';

import 'package:flutter/material.dart';

// Package imports:
import 'package:redux/redux.dart';

// Project imports:
import 'package:invoiceninja_flutter/.env.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/data/repositories/client_repository.dart';
import 'package:invoiceninja_flutter/main_app.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/client/client_actions.dart';
import 'package:invoiceninja_flutter/redux/product/product_actions.dart';
import 'package:invoiceninja_flutter/redux/ui/ui_actions.dart';
import 'package:invoiceninja_flutter/ui/client/client_pdf_vm.dart';
import 'package:invoiceninja_flutter/ui/client/client_screen.dart';
import 'package:invoiceninja_flutter/ui/client/edit/client_edit_vm.dart';
import 'package:invoiceninja_flutter/ui/client/view/client_view_vm.dart';

List<Middleware<AppState>> createStoreClientsMiddleware([
  ClientRepository repository = const ClientRepository(),
]) {
  final viewClientList = _viewClientList();
  final viewClient = _viewClient();
  final editClient = _editClient();
  final showPdfClient = _showPdfClient();
  final loadClients = _loadClients(repository);
  final loadClient = _loadClient(repository);
  final saveClient = _saveClient(repository);
  final archiveClient = _archiveClient(repository);
  final deleteClient = _deleteClient(repository);
  final purgeClient = _purgeClient(repository);
  final restoreClient = _restoreClient(repository);
  final saveDocument = _saveDocument(repository);

  return [
    TypedMiddleware<AppState, ViewClientList>(viewClientList),
    TypedMiddleware<AppState, ViewClient>(viewClient),
    TypedMiddleware<AppState, EditClient>(editClient),
    TypedMiddleware<AppState, ShowPdfClient>(showPdfClient),
    TypedMiddleware<AppState, LoadClients>(loadClients),
    TypedMiddleware<AppState, LoadClient>(loadClient),
    TypedMiddleware<AppState, SaveClientRequest>(saveClient),
    TypedMiddleware<AppState, ArchiveClientsRequest>(archiveClient),
    TypedMiddleware<AppState, DeleteClientsRequest>(deleteClient),
    TypedMiddleware<AppState, PurgeClientRequest>(purgeClient),
    TypedMiddleware<AppState, RestoreClientsRequest>(restoreClient),
    TypedMiddleware<AppState, SaveClientDocumentRequest>(saveDocument),
  ];
}

Middleware<AppState> _editClient() {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as EditClient;

    next(action);

    store.dispatch(UpdateCurrentRoute(ClientEditScreen.route));

    if (store.state.prefState.isMobile) {
      navigatorKey.currentState.pushNamed(ClientEditScreen.route);
    }
  };
}

Middleware<AppState> _viewClient() {
  return (Store<AppState> store, dynamic dynamicAction,
      NextDispatcher next) async {
    final action = dynamicAction as ViewClient;

    next(action);

    store.dispatch(UpdateCurrentRoute(ClientViewScreen.route));

    if (store.state.prefState.isMobile) {
      navigatorKey.currentState.pushNamed(ClientViewScreen.route);
    }
  };
}

Middleware<AppState> _viewClientList() {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as ViewClientList;

    next(action);

    if (store.state.isStale) {
      store.dispatch(RefreshData());
    }

    store.dispatch(UpdateCurrentRoute(ClientScreen.route));

    if (store.state.prefState.isMobile) {
      navigatorKey.currentState.pushNamedAndRemoveUntil(
          ClientScreen.route, (Route<dynamic> route) => false);
    }
  };
}

Middleware<AppState> _archiveClient(ClientRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as ArchiveClientsRequest;
    final prevClients =
        action.clientIds.map((id) => store.state.clientState.map[id]).toList();
    repository
        .bulkAction(
            store.state.credentials, action.clientIds, EntityAction.archive)
        .then((List<ClientEntity> clients) {
      store.dispatch(ArchiveClientsSuccess(clients));
      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((Object error) {
      print(error);
      store.dispatch(ArchiveClientsFailure(prevClients));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}

Middleware<AppState> _deleteClient(ClientRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as DeleteClientsRequest;
    final prevClients =
        action.clientIds.map((id) => store.state.clientState.map[id]).toList();
    repository
        .bulkAction(
            store.state.credentials, action.clientIds, EntityAction.delete)
        .then((List<ClientEntity> clients) {
      store.dispatch(DeleteClientsSuccess(clients));
      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((Object error) {
      print(error);
      store.dispatch(DeleteClientsFailure(prevClients));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}

Middleware<AppState> _purgeClient(ClientRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as PurgeClientRequest;
    repository.purge(store.state.credentials, action.clientId).then((_) {
      store.dispatch(PurgeClientSuccess());
      store.dispatch(RefreshData(
          clearData: true,
          completer: Completer<Null>()
            ..future.then((value) {
              action.completer.complete(null);
            })));
    }).catchError((Object error) {
      print(error);
      store.dispatch(PurgeClientFailure(error));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}

Middleware<AppState> _restoreClient(ClientRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as RestoreClientsRequest;
    final prevClients =
        action.clientIds.map((id) => store.state.clientState.map[id]).toList();
    repository
        .bulkAction(
            store.state.credentials, action.clientIds, EntityAction.restore)
        .then((List<ClientEntity> clients) {
      store.dispatch(RestoreClientSuccess(clients));
      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((Object error) {
      print(error);
      store.dispatch(RestoreClientFailure(prevClients));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}

Middleware<AppState> _saveClient(ClientRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as SaveClientRequest;
    repository
        .saveData(store.state.credentials, action.client)
        .then((ClientEntity client) {
      if (action.client.isNew) {
        store.dispatch(AddClientSuccess(client));
      } else {
        store.dispatch(SaveClientSuccess(client));
      }

      action.completer.complete(client);

      final clientUIState = store.state.clientUIState;
      if (clientUIState.saveCompleter != null) {
        clientUIState.saveCompleter.complete(client);
      }
    }).catchError((Object error) {
      print(error);
      store.dispatch(SaveClientFailure(error));
      action.completer.completeError(error);
    });

    next(action);
  };
}

Middleware<AppState> _loadClient(ClientRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as LoadClient;

    if (Config.DEMO_MODE) {
      next(action);
      return;
    }

    store.dispatch(LoadClientRequest());
    repository
        .loadItem(store.state.credentials, action.clientId)
        .then((client) {
      store.dispatch(LoadClientSuccess(client));

      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((Object error) {
      print(error);
      store.dispatch(LoadClientFailure(error));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}

Middleware<AppState> _loadClients(ClientRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as LoadClients;

    store.dispatch(LoadClientsRequest());
    repository.loadList(store.state.credentials).then((data) {
      store.dispatch(LoadClientsSuccess(data));
      if (action.completer != null) {
        action.completer.complete(null);
      }
      store.dispatch(LoadProducts());
    }).catchError((Object error) {
      print(error);
      store.dispatch(LoadClientsFailure(error));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}

Middleware<AppState> _saveDocument(ClientRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as SaveClientDocumentRequest;
    if (store.state.isEnterprisePlan) {
      repository
          .uploadDocument(
              store.state.credentials, action.client, action.multipartFile)
          .then((client) {
        store.dispatch(SaveClientSuccess(client));
        action.completer.complete(null);
      }).catchError((Object error) {
        print(error);
        store.dispatch(SaveClientDocumentFailure(error));
        action.completer.completeError(error);
      });
    } else {
      const error = 'Uploading documents requires an enterprise plan';
      store.dispatch(SaveClientDocumentFailure(error));
      action.completer.completeError(error);
    }

    next(action);
  };
}

Middleware<AppState> _showPdfClient() {
  return (Store<AppState> store, dynamic dynamicAction,
      NextDispatcher next) async {
    final action = dynamicAction as ShowPdfClient;

    next(action);

    store.dispatch(UpdateCurrentRoute(ClientPdfScreen.route));

    if (store.state.prefState.isMobile) {
      navigatorKey.currentState.pushNamed(ClientPdfScreen.route);
    }
  };
}
