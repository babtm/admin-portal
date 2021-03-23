import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/entities.dart';
import 'package:invoiceninja_flutter/data/models/user_model.dart';
import 'package:invoiceninja_flutter/data/web_client.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/company/company_actions.dart';
import 'package:invoiceninja_flutter/redux/settings/settings_actions.dart';
import 'package:invoiceninja_flutter/redux/static/static_selectors.dart';
import 'package:invoiceninja_flutter/ui/app/app_builder.dart';
import 'package:invoiceninja_flutter/ui/app/entity_dropdown.dart';
import 'package:invoiceninja_flutter/ui/app/forms/app_form.dart';
import 'package:invoiceninja_flutter/ui/app/forms/decorated_form_field.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/utils/dialogs.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:invoiceninja_flutter/utils/platforms.dart';

class SettingsWizard extends StatefulWidget {
  const SettingsWizard({
    @required this.user,
  });
  final UserEntity user;

  @override
  _SettingsWizardState createState() => _SettingsWizardState();
}

class _SettingsWizardState extends State<SettingsWizard> {
  static final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: '_settingsWizard');
  final FocusScopeNode _focusNode = FocusScopeNode();
  final _debouncer = Debouncer(milliseconds: kMillisecondsToDebounceSave);
  bool _autoValidate = false;
  bool _isSubdomainUnique = false;
  bool _isCheckingSubdomain = false;
  String _currencyId = kCurrencyUSDollar;
  String _languageId = kLanguageEnglish;
  final _nameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _subdomainController = TextEditingController();
  final _webClient = WebClient();

  List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();

    _firstNameController.text = widget.user.firstName;
    _lastNameController.text = widget.user.lastName;

    _controllers = [
      _nameController,
      _firstNameController,
      _lastNameController,
      _subdomainController,
    ];
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controllers.forEach((dynamic controller) {
      controller.dispose();
    });
    super.dispose();
  }

  void _validateSubdomain() {
    _debouncer.run(() {
      final subdomain = _subdomainController.text.trim();

      if (subdomain.isEmpty) {
        return;
      }

      final store = StoreProvider.of<AppState>(context);
      final state = store.state;
      final credentials = state.credentials;
      final url = '${credentials.url}/check_subdomain';

      _webClient
          .post(url, credentials.token,
              data: jsonEncode(
                {'subdomain': subdomain},
              ))
          .then((dynamic data) {
        print('## DATA: $data');
        setState(() => _isSubdomainUnique = true);
      }).catchError((Object error) {
        setState(() => _isSubdomainUnique = false);
        //showErrorDialog(context: context, message: '$error');
      });
    });
  }

  void _onSavePressed() {
    final bool isValid = _formKey.currentState.validate();

    setState(() {
      _autoValidate = !isValid;
    });

    if (!isValid) {
      return;
    }

    final store = StoreProvider.of<AppState>(context);
    final navigator = Navigator.of(context);
    final state = store.state;
    passwordCallback(
        context: context,
        callback: (password, idToken) {
          final localization = AppLocalization.of(context);
          final completer = Completer<Null>();
          completer.future.then((value) {
            final toastCompleter =
                snackBarCompleter<Null>(context, localization.savedSettings);
            toastCompleter.future.then((value) => navigator.pop());
            store.dispatch(
              SaveCompanyRequest(
                completer: toastCompleter,
                company: state.company.rebuild(
                  (b) => b
                    ..subdomain = _subdomainController.text.trim()
                    ..settings.name = _nameController.text.trim()
                    ..settings.currencyId = _currencyId
                    ..settings.languageId = _languageId,
                ),
              ),
            );
          });
          store.dispatch(
            SaveAuthUserRequest(
              completer: completer,
              user: state.user.rebuild((b) => b
                ..firstName = _firstNameController.text.trim()
                ..lastName = _lastNameController.text.trim()),
              password: password,
              idToken: idToken,
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final store = StoreProvider.of<AppState>(context);
    final state = store.state;

    final companyName = DecoratedFormField(
      autofocus: true,
      label: localization.companyName,
      autovalidate: _autoValidate,
      controller: _nameController,
      validator: (value) =>
          value.isEmpty ? localization.pleaseEnterAValue : null,
    );

    final firstName = DecoratedFormField(
      label: localization.firstName,
      autovalidate: _autoValidate,
      controller: _firstNameController,
      validator: (value) =>
          value.isEmpty ? localization.pleaseEnterAValue : null,
    );

    final lastName = DecoratedFormField(
      label: localization.lastName,
      autovalidate: _autoValidate,
      controller: _lastNameController,
      validator: (value) =>
          value.isEmpty ? localization.pleaseEnterAValue : null,
    );

    final currency = EntityDropdown(
      key: ValueKey('__currency_${_currencyId}__'),
      entityType: EntityType.currency,
      entityList: memoizedCurrencyList(state.staticState.currencyMap),
      labelText: localization.currency,
      entityId: _currencyId,
      onSelected: (SelectableEntity currency) =>
          setState(() => _currencyId = currency?.id),
      validator: (dynamic value) =>
          value.isEmpty ? localization.pleaseEnterAValue : null,
    );

    final language = EntityDropdown(
      key: ValueKey('__language_${_languageId}__'),
      entityType: EntityType.language,
      entityList: memoizedLanguageList(state.staticState.languageMap),
      labelText: localization.language,
      entityId: _languageId,
      onSelected: (SelectableEntity language) {
        setState(() => _languageId = language?.id);
        store.dispatch(UpdateCompanyLanguage(languageId: language?.id));
        AppBuilder.of(context).rebuild();
      },
      validator: (dynamic value) =>
          value.isEmpty ? localization.pleaseEnterAValue : null,
    );

    final darkMode = LayoutBuilder(builder: (context, constraints) {
      return ToggleButtons(
        children: [
          Text(localization.light),
          Text(localization.dark),
        ],
        constraints: BoxConstraints.expand(
            width: (constraints.maxWidth / 2) - 2, height: 40),
        isSelected: [
          !state.prefState.enableDarkMode,
          state.prefState.enableDarkMode,
        ],
        onPressed: (index) {
          final isDark = index == 1;
          store.dispatch(
            UpdateUserPreferences(
              enableDarkMode: isDark,
              colorTheme: isDark ? kColorThemeDark : kColorThemeLight,
            ),
          );
          AppBuilder.of(context).rebuild();
        },
      );
    });

    final subdomain = DecoratedFormField(
      label: localization.subdomain,
      autovalidate: _autoValidate,
      controller: _subdomainController,
      validator: (value) {
        if (value.isEmpty) {
          return localization.pleaseEnterAValue;
        } else if (!_isSubdomainUnique) {
          return localization.subdomainIsNotAvailable;
        }

        return null;
      },
      suffixIcon: _isCheckingSubdomain
          ? null
          : Icon(_isSubdomainUnique ? Icons.check_circle : Icons.error_outline),
      onChanged: (value) => _validateSubdomain(),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9\-]')),
      ],
    );

    return AlertDialog(
      title: Text(localization.welcomeToInvoiceNinja),
      content: AppForm(
        focusNode: _focusNode,
        formKey: _formKey,
        child: SingleChildScrollView(
          child: Container(
            width: isMobile(context) ? double.infinity : 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: isMobile(context)
                  ? [
                      companyName,
                      if (state.isHosted) subdomain,
                      firstName,
                      lastName,
                      language,
                      currency,
                      darkMode,
                    ]
                  : [
                      Row(
                        children: [
                          Expanded(child: companyName),
                          SizedBox(width: kTableColumnGap),
                          Expanded(child: darkMode),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: firstName),
                          SizedBox(width: kTableColumnGap),
                          Expanded(child: lastName),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: language),
                          SizedBox(width: kTableColumnGap),
                          Expanded(child: currency),
                        ],
                      ),
                      if (state.isHosted)
                        Row(
                          children: [
                            Expanded(child: subdomain),
                            SizedBox(width: kTableColumnGap),
                            Expanded(child: SizedBox()),
                          ],
                        ),
                    ],
            ),
          ),
        ),
      ),
      actions: [
        if (!state.isSaving)
          TextButton(
              onPressed: _onSavePressed,
              child: Text(localization.save.toUpperCase()))
      ],
    );
  }
}
