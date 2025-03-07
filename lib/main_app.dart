// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:redux/redux.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Project imports:
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/company/company_selectors.dart';
import 'package:invoiceninja_flutter/redux/ui/pref_state.dart';
import 'package:invoiceninja_flutter/ui/app/app_builder.dart';
import 'package:invoiceninja_flutter/ui/app/change_layout_banner.dart';
import 'package:invoiceninja_flutter/ui/app/main_screen.dart';
import 'package:invoiceninja_flutter/ui/app/screen_imports.dart';
import 'package:invoiceninja_flutter/ui/app/web_session_timeout.dart';
import 'package:invoiceninja_flutter/ui/app/web_socket_refresh.dart';
import 'package:invoiceninja_flutter/ui/auth/init_screen.dart';
import 'package:invoiceninja_flutter/ui/auth/lock_screen.dart';
import 'package:invoiceninja_flutter/ui/auth/login_vm.dart';
import 'package:invoiceninja_flutter/ui/client/client_pdf_vm.dart';
import 'package:invoiceninja_flutter/ui/company_gateway/company_gateway_screen.dart';
import 'package:invoiceninja_flutter/ui/credit/credit_email_vm.dart';
import 'package:invoiceninja_flutter/ui/credit/credit_pdf_vm.dart';
import 'package:invoiceninja_flutter/ui/credit/credit_screen.dart';
import 'package:invoiceninja_flutter/ui/credit/credit_screen_vm.dart';
import 'package:invoiceninja_flutter/ui/credit/edit/credit_edit_vm.dart';
import 'package:invoiceninja_flutter/ui/credit/view/credit_view_vm.dart';
import 'package:invoiceninja_flutter/ui/design/design_screen.dart';
import 'package:invoiceninja_flutter/ui/design/design_screen_vm.dart';
import 'package:invoiceninja_flutter/ui/design/edit/design_edit_vm.dart';
import 'package:invoiceninja_flutter/ui/design/view/design_view_vm.dart';
import 'package:invoiceninja_flutter/ui/expense_category/edit/expense_category_edit_vm.dart';
import 'package:invoiceninja_flutter/ui/expense_category/expense_category_screen.dart';
import 'package:invoiceninja_flutter/ui/expense_category/expense_category_screen_vm.dart';
import 'package:invoiceninja_flutter/ui/expense_category/view/expense_category_view_vm.dart';
import 'package:invoiceninja_flutter/ui/invoice/invoice_pdf_vm.dart';
import 'package:invoiceninja_flutter/ui/payment/refund/payment_refund_vm.dart';
import 'package:invoiceninja_flutter/ui/payment_term/edit/payment_term_edit_vm.dart';
import 'package:invoiceninja_flutter/ui/payment_term/payment_term_screen.dart';
import 'package:invoiceninja_flutter/ui/payment_term/payment_term_screen_vm.dart';
import 'package:invoiceninja_flutter/ui/payment_term/view/payment_term_view_vm.dart';
import 'package:invoiceninja_flutter/ui/quote/quote_pdf_vm.dart';
import 'package:invoiceninja_flutter/ui/recurring_expense/edit/recurring_expense_edit_vm.dart';
import 'package:invoiceninja_flutter/ui/recurring_expense/recurring_expense_screen.dart';
import 'package:invoiceninja_flutter/ui/recurring_expense/recurring_expense_screen_vm.dart';
import 'package:invoiceninja_flutter/ui/recurring_expense/view/recurring_expense_view_vm.dart';
import 'package:invoiceninja_flutter/ui/recurring_invoice/edit/recurring_invoice_edit_vm.dart';
import 'package:invoiceninja_flutter/ui/recurring_invoice/recurring_invoice_pdf_vm.dart';
import 'package:invoiceninja_flutter/ui/recurring_invoice/recurring_invoice_screen.dart';
import 'package:invoiceninja_flutter/ui/recurring_invoice/recurring_invoice_screen_vm.dart';
import 'package:invoiceninja_flutter/ui/recurring_invoice/view/recurring_invoice_view_vm.dart';
import 'package:invoiceninja_flutter/ui/reports/reports_screen.dart';
import 'package:invoiceninja_flutter/ui/reports/reports_screen_vm.dart';
import 'package:invoiceninja_flutter/ui/settings/account_management_vm.dart';
import 'package:invoiceninja_flutter/ui/settings/device_settings_vm.dart';
import 'package:invoiceninja_flutter/ui/settings/expense_settings_vm.dart';
import 'package:invoiceninja_flutter/ui/settings/online_payments_vm.dart';
import 'package:invoiceninja_flutter/ui/settings/settings_screen_vm.dart';
import 'package:invoiceninja_flutter/ui/settings/task_settings_vm.dart';
import 'package:invoiceninja_flutter/ui/settings/tax_settings_vm.dart';
import 'package:invoiceninja_flutter/ui/subscription/edit/subscription_edit_vm.dart';
import 'package:invoiceninja_flutter/ui/subscription/subscription_screen.dart';
import 'package:invoiceninja_flutter/ui/subscription/subscription_screen_vm.dart';
import 'package:invoiceninja_flutter/ui/subscription/view/subscription_view_vm.dart';
import 'package:invoiceninja_flutter/ui/task_status/edit/task_status_edit_vm.dart';
import 'package:invoiceninja_flutter/ui/task_status/task_status_screen.dart';
import 'package:invoiceninja_flutter/ui/task_status/task_status_screen_vm.dart';
import 'package:invoiceninja_flutter/ui/task_status/view/task_status_view_vm.dart';
import 'package:invoiceninja_flutter/ui/tax_rate/tax_rate_screen.dart';
import 'package:invoiceninja_flutter/ui/token/edit/token_edit_vm.dart';
import 'package:invoiceninja_flutter/ui/token/token_screen.dart';
import 'package:invoiceninja_flutter/ui/token/token_screen_vm.dart';
import 'package:invoiceninja_flutter/ui/token/view/token_view_vm.dart';
import 'package:invoiceninja_flutter/ui/user/user_screen.dart';
import 'package:invoiceninja_flutter/ui/webhook/edit/webhook_edit_vm.dart';
import 'package:invoiceninja_flutter/ui/webhook/view/webhook_view_vm.dart';
import 'package:invoiceninja_flutter/ui/webhook/webhook_screen.dart';
import 'package:invoiceninja_flutter/ui/webhook/webhook_screen_vm.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:invoiceninja_flutter/utils/platforms.dart';

// STARTER: import - do not remove comment

import 'package:invoiceninja_flutter/utils/web_stub.dart'
    if (dart.library.html) 'package:invoiceninja_flutter/utils/web.dart';

final navigatorKey = GlobalKey<NavigatorState>();

extension NavigatorKeyUtils on GlobalKey<NavigatorState> {
  AppLocalization get localization {
    return AppLocalization.of(currentContext);
  }

  Store<AppState> get store {
    return StoreProvider.of<AppState>(currentContext);
  }
}

class InvoiceNinjaApp extends StatefulWidget {
  const InvoiceNinjaApp({Key key, this.store}) : super(key: key);
  final Store<AppState> store;

  @override
  InvoiceNinjaAppState createState() => InvoiceNinjaAppState();
}

class InvoiceNinjaAppState extends State<InvoiceNinjaApp> {
  bool _authenticated = false;

  Future<Null> _authenticate() async {
    bool authenticated = false;

    try {
      authenticated = await LocalAuthentication().authenticate(
          localizedReason: 'Please authenticate to access the app',
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: false);
    } catch (e) {
      print(e);
    }

    if (authenticated) {
      setState(() => _authenticated = true);
    }
  }

  @override
  void initState() {
    super.initState();

    WebUtils.warnChanges(widget.store);

    Timer.periodic(Duration(milliseconds: kMillisecondsToTimerRefreshData),
        (_) {
      final store = widget.store;
      final state = store.state;

      if (!state.authState.isAuthenticated) {
        return;
      }

      if (!state.uiState.hasRecentActivity) {
        return;
      }

      final millisecondsSinceLastUpdate =
          DateTime.now().millisecondsSinceEpoch -
              state.userCompanyState.lastUpdated;

      if (millisecondsSinceLastUpdate > kMillisecondsToTimerRefreshData) {
        store.dispatch(RefreshData());
      }
    });
  }

  /*
  @override
  void initState() {
    super.initState();

    const QuickActions quickActions = QuickActions();
    quickActions.initialize((String shortcutType) {
      if (shortcutType == 'action_new_client') {
        widget.store
            .dispatch(EditClient(context: context, client: ClientEntity()));
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
          type: 'action_new_client',
          localizedTitle: 'New Client',
          icon: 'AppIcon'),
    ]);
  }
  */

  @override
  void didChangeDependencies() {
    final state = widget.store.state;
    if (state.prefState.requireAuthentication && !_authenticated) {
      _authenticate();
    }
    super.didChangeDependencies();
  }

  Route<dynamic> generateRoute(RouteSettings settings) {
    /*
    print('## generateRoute: ${settings.name}, isInitial: ${settings.isInitialRoute}');
    print('## pathname: ${html5.window.location.pathname} hash: ${html5.window.location.hash}, href: ${html5.window.location.href}');
    html5.window.history.replaceState(null, settings.name, '/#${settings.name}');
    widget.store.dispatch(UpdateCurrentRoute(settings.name));
    */
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute<dynamic>(builder: (_) => LoginScreen());
      default:
        return MaterialPageRoute<dynamic>(builder: (_) => MainScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreProvider<AppState>(
      store: widget.store,
      child: WebSessionTimeout(
        child: AppBuilder(builder: (context) {
          final store = widget.store;
          final state = store.state;
          final hasAccentColor = state.hasAccentColor;
          final accentColor = state.accentColor;
          const fontFamily = kIsWeb ? 'Roboto' : null;
          final pageTransitionsTheme = PageTransitionsTheme(builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
          });
          Intl.defaultLocale = localeSelector(state);
          final locale = AppLocalization.createLocale(localeSelector(state));

          final textButtonTheme = TextButton.styleFrom(
            minimumSize: Size(88, 36),
            padding: EdgeInsets.symmetric(horizontal: 16),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(kBorderRadius)),
            ),
          );

          final outlinedButtonTheme = OutlinedButton.styleFrom(
            primary:
                state.prefState.enableDarkMode ? Colors.white : Colors.black87,
          );

          return StyledToast(
            locale: locale,
            duration: Duration(seconds: 3),
            backgroundColor:
                state.prefState.enableDarkMode ? Colors.white : Colors.black,
            textStyle: TextStyle(
              color: state.prefState.enableDarkMode
                  ? Colors.black87
                  : Colors.white,
            ),
            child: WebSocketRefresh(
              companyId: state.company?.id,
              child: MaterialApp(
                builder: (BuildContext context, Widget child) {
                  final MediaQueryData data = MediaQuery.of(context);
                  return MediaQuery(
                    data: data.copyWith(
                      textScaleFactor: state.prefState.textScaleFactor,
                      alwaysUse24HourFormat:
                          state.company?.settings?.enableMilitaryTime ?? false,
                    ),
                    child: child,
                  );
                },
                scrollBehavior: MyCustomScrollBehavior(),
                navigatorKey: navigatorKey,
                supportedLocales: kLanguages
                    .map(
                        (String locale) => AppLocalization.createLocale(locale))
                    .toList(),
                debugShowCheckedModeBanner: false,
                //showPerformanceOverlay: true,
                navigatorObservers: [
                  SentryNavigatorObserver(),
                ],
                localizationsDelegates: [
                  const AppLocalizationsDelegate(),
                  GlobalCupertinoLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate
                ],
                home: state.prefState.requireAuthentication && !_authenticated
                    ? LockScreen(onAuthenticatePressed: _authenticate)
                    : InitScreen(),
                locale: locale,
                theme: state.prefState.enableDarkMode
                    ? ThemeData(
                        colorScheme: ColorScheme.dark().copyWith(
                          secondary: accentColor,
                          primary: accentColor,
                        ),
                        pageTransitionsTheme: pageTransitionsTheme,
                        indicatorColor: accentColor,
                        textSelectionTheme: TextSelectionThemeData(
                          selectionHandleColor: accentColor,
                        ),
                        fontFamily: fontFamily,
                        backgroundColor: Colors.black,
                        canvasColor: Colors.black,
                        cardColor: const Color(0xFF1B1C1E),
                        bottomAppBarColor: const Color(0xFF1B1C1E),
                        primaryColorDark: Colors.black,
                        textButtonTheme:
                            TextButtonThemeData(style: textButtonTheme),
                        outlinedButtonTheme:
                            OutlinedButtonThemeData(style: outlinedButtonTheme),
                      )
                    : ThemeData(
                        colorScheme: ColorScheme.fromSwatch()
                            .copyWith(secondary: accentColor),
                        pageTransitionsTheme: pageTransitionsTheme,
                        primaryColor: accentColor,
                        indicatorColor: accentColor,
                        textSelectionTheme: TextSelectionThemeData(
                          selectionColor: accentColor,
                        ),
                        fontFamily: fontFamily,
                        backgroundColor: Colors.white,
                        canvasColor: Colors.white,
                        cardColor: Colors.white,
                        bottomAppBarColor: Colors.white,
                        primaryColorDark: hasAccentColor
                            ? accentColor
                            : const Color(0xFF0D5D91),
                        primaryColorLight: hasAccentColor
                            ? accentColor
                            : const Color(0xFF5dabf4),
                        scaffoldBackgroundColor: const Color(0xFFE4E8EB),
                        tabBarTheme: TabBarTheme(
                          labelColor:
                              hasAccentColor ? Colors.white : Colors.black,
                          unselectedLabelColor: hasAccentColor
                              ? Colors.white.withOpacity(.65)
                              : Colors.black.withOpacity(.65),
                        ),
                        iconTheme: IconThemeData(
                          color: hasAccentColor ? null : accentColor,
                        ),
                        appBarTheme: AppBarTheme(
                          color: hasAccentColor ? accentColor : Colors.white,
                          iconTheme: IconThemeData(
                            color: hasAccentColor ? Colors.white : accentColor,
                          ),
                          titleTextStyle: TextStyle(
                              fontSize: 20,
                              color:
                                  hasAccentColor ? Colors.white : Colors.black),
                        ),
                        textButtonTheme:
                            TextButtonThemeData(style: textButtonTheme),
                        outlinedButtonTheme:
                            OutlinedButtonThemeData(style: outlinedButtonTheme),
                      ),
                title: kAppName,
                onGenerateRoute: isMobile(context) ? null : generateRoute,
                routes: isMobile(context)
                    ? {
                        LoginScreen.route: (context) => LoginScreen(),
                        MainScreen.route: (context) => MainScreen(),
                        DashboardScreenBuilder.route: (context) =>
                            ChangeLayoutBanner(
                              suggestedLayout: AppLayout.mobile,
                              appLayout: state.prefState.appLayout,
                              child: DashboardScreenBuilder(),
                            ),
                        ProductScreen.route: (context) =>
                            ProductScreenBuilder(),
                        ProductViewScreen.route: (context) =>
                            ProductViewScreen(),
                        ProductEditScreen.route: (context) =>
                            ProductEditScreen(),
                        ClientScreen.route: (context) => ClientScreenBuilder(),
                        ClientViewScreen.route: (context) => ClientViewScreen(),
                        ClientEditScreen.route: (context) => ClientEditScreen(),
                        ClientPdfScreen.route: (context) => ClientPdfScreen(),
                        InvoiceScreen.route: (context) =>
                            InvoiceScreenBuilder(),
                        InvoiceViewScreen.route: (context) =>
                            InvoiceViewScreen(),
                        InvoiceEditScreen.route: (context) =>
                            InvoiceEditScreen(),
                        InvoiceEmailScreen.route: (context) =>
                            InvoiceEmailScreen(),
                        InvoicePdfScreen.route: (context) => InvoicePdfScreen(),
                        DocumentScreen.route: (context) =>
                            DocumentScreenBuilder(),
                        DocumentViewScreen.route: (context) =>
                            DocumentViewScreen(),
                        DocumentEditScreen.route: (context) =>
                            DocumentEditScreen(),
                        ExpenseScreen.route: (context) =>
                            ExpenseScreenBuilder(),
                        ExpenseViewScreen.route: (context) =>
                            ExpenseViewScreen(),
                        ExpenseEditScreen.route: (context) =>
                            ExpenseEditScreen(),
                        VendorScreen.route: (context) => VendorScreenBuilder(),
                        VendorViewScreen.route: (context) => VendorViewScreen(),
                        VendorEditScreen.route: (context) => VendorEditScreen(),
                        TaskScreen.route: (context) => TaskScreenBuilder(),
                        TaskViewScreen.route: (context) => TaskViewScreen(),
                        TaskEditScreen.route: (context) => TaskEditScreen(),
                        ProjectScreen.route: (context) =>
                            ProjectScreenBuilder(),
                        ProjectViewScreen.route: (context) =>
                            ProjectViewScreen(),
                        ProjectEditScreen.route: (context) =>
                            ProjectEditScreen(),
                        PaymentScreen.route: (context) =>
                            PaymentScreenBuilder(),
                        PaymentViewScreen.route: (context) =>
                            PaymentViewScreen(),
                        PaymentEditScreen.route: (context) =>
                            PaymentEditScreen(),
                        PaymentRefundScreen.route: (context) =>
                            PaymentRefundScreen(),
                        QuoteScreen.route: (context) => QuoteScreenBuilder(),
                        QuoteViewScreen.route: (context) => QuoteViewScreen(),
                        QuoteEditScreen.route: (context) => QuoteEditScreen(),
                        QuoteEmailScreen.route: (context) => QuoteEmailScreen(),
                        QuotePdfScreen.route: (context) => QuotePdfScreen(),
                        // STARTER: routes - do not remove comment
                        RecurringExpenseScreen.route: (context) =>
                            RecurringExpenseScreenBuilder(),
                        RecurringExpenseViewScreen.route: (context) =>
                            RecurringExpenseViewScreen(),
                        RecurringExpenseEditScreen.route: (context) =>
                            RecurringExpenseEditScreen(),

                        SubscriptionScreen.route: (context) =>
                            SubscriptionScreenBuilder(),
                        SubscriptionViewScreen.route: (context) =>
                            SubscriptionViewScreen(),
                        SubscriptionEditScreen.route: (context) =>
                            SubscriptionEditScreen(),

                        TaskStatusScreen.route: (context) =>
                            TaskStatusScreenBuilder(),
                        TaskStatusViewScreen.route: (context) =>
                            TaskStatusViewScreen(),
                        TaskStatusEditScreen.route: (context) =>
                            TaskStatusEditScreen(),
                        ExpenseCategoryScreen.route: (context) =>
                            ExpenseCategoryScreenBuilder(),
                        ExpenseCategoryViewScreen.route: (context) =>
                            ExpenseCategoryViewScreen(),
                        ExpenseCategoryEditScreen.route: (context) =>
                            ExpenseCategoryEditScreen(),
                        RecurringInvoiceScreen.route: (context) =>
                            RecurringInvoiceScreenBuilder(),
                        RecurringInvoiceViewScreen.route: (context) =>
                            RecurringInvoiceViewScreen(),
                        RecurringInvoiceEditScreen.route: (context) =>
                            RecurringInvoiceEditScreen(),
                        RecurringInvoicePdfScreen.route: (context) =>
                            RecurringInvoicePdfScreen(),
                        WebhookScreen.route: (context) =>
                            WebhookScreenBuilder(),
                        WebhookViewScreen.route: (context) =>
                            WebhookViewScreen(),
                        WebhookEditScreen.route: (context) =>
                            WebhookEditScreen(),
                        TokenScreen.route: (context) => TokenScreenBuilder(),
                        TokenViewScreen.route: (context) => TokenViewScreen(),
                        TokenEditScreen.route: (context) => TokenEditScreen(),
                        PaymentTermScreen.route: (context) =>
                            PaymentTermScreenBuilder(),
                        PaymentTermEditScreen.route: (context) =>
                            PaymentTermEditScreen(),
                        PaymentTermViewScreen.route: (context) =>
                            PaymentTermViewScreen(),
                        DesignScreen.route: (context) => DesignScreenBuilder(),
                        DesignViewScreen.route: (context) => DesignViewScreen(),
                        DesignEditScreen.route: (context) => DesignEditScreen(),
                        CreditScreen.route: (context) => CreditScreenBuilder(),
                        CreditViewScreen.route: (context) => CreditViewScreen(),
                        CreditEditScreen.route: (context) => CreditEditScreen(),
                        CreditEmailScreen.route: (context) =>
                            CreditEmailScreen(),
                        CreditPdfScreen.route: (context) => CreditPdfScreen(),
                        UserScreen.route: (context) => UserScreenBuilder(),
                        UserViewScreen.route: (context) => UserViewScreen(),
                        UserEditScreen.route: (context) => UserEditScreen(),
                        GroupSettingsScreen.route: (context) =>
                            GroupScreenBuilder(),
                        GroupViewScreen.route: (context) => GroupViewScreen(),
                        GroupEditScreen.route: (context) => GroupEditScreen(),
                        SettingsScreen.route: (context) =>
                            SettingsScreenBuilder(),
                        ReportsScreen.route: (context) =>
                            ReportsScreenBuilder(),
                        CompanyDetailsScreen.route: (context) =>
                            CompanyDetailsScreen(),
                        UserDetailsScreen.route: (context) =>
                            UserDetailsScreen(),
                        LocalizationScreen.route: (context) =>
                            LocalizationScreen(),
                        OnlinePaymentsScreen.route: (context) =>
                            OnlinePaymentsScreen(),
                        CompanyGatewayScreen.route: (context) =>
                            CompanyGatewayScreenBuilder(),
                        CompanyGatewayViewScreen.route: (context) =>
                            CompanyGatewayViewScreen(),
                        CompanyGatewayEditScreen.route: (context) =>
                            CompanyGatewayEditScreen(),
                        TaxSettingsScreen.route: (context) =>
                            TaxSettingsScreen(),
                        TaxRateSettingsScreen.route: (context) =>
                            TaxRateScreenBuilder(),
                        TaxRateViewScreen.route: (context) =>
                            TaxRateViewScreen(),
                        TaxRateEditScreen.route: (context) =>
                            TaxRateEditScreen(),
                        ProductSettingsScreen.route: (context) =>
                            ProductSettingsScreen(),
                        ExpenseSettingsScreen.route: (context) =>
                            ExpenseSettingsScreen(),
                        TaskSettingsScreen.route: (context) =>
                            TaskSettingsScreen(),
                        ImportExportScreen.route: (context) =>
                            ImportExportScreen(),
                        DeviceSettingsScreen.route: (context) =>
                            DeviceSettingsScreen(),
                        AccountManagementScreen.route: (context) =>
                            AccountManagementScreen(),
                        CustomFieldsScreen.route: (context) =>
                            CustomFieldsScreen(),
                        GeneratedNumbersScreen.route: (context) =>
                            GeneratedNumbersScreen(),
                        WorkflowSettingsScreen.route: (context) =>
                            WorkflowSettingsScreen(),
                        InvoiceDesignScreen.route: (context) =>
                            InvoiceDesignScreen(),
                        ClientPortalScreen.route: (context) =>
                            ClientPortalScreen(),
                        EmailSettingsScreen.route: (context) =>
                            EmailSettingsScreen(),
                        TemplatesAndRemindersScreen.route: (context) =>
                            TemplatesAndRemindersScreen(),
                        CreditCardsAndBanksScreen.route: (context) =>
                            CreditCardsAndBanksScreen(),
                        DataVisualizationsScreen.route: (context) =>
                            DataVisualizationsScreen(),
                      }
                    : {},
              ),
            ),
          );
        }),
      ),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
