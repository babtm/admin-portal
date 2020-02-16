import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:invoiceninja_flutter/utils/enums.dart';
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/invoice_model.dart';
import 'package:invoiceninja_flutter/data/models/company_model.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/reports/reports_state.dart';
import 'package:invoiceninja_flutter/redux/static/static_state.dart';
import 'package:invoiceninja_flutter/ui/reports/reports_screen.dart';
import 'package:invoiceninja_flutter/utils/formatting.dart';
import 'package:memoize/memoize.dart';

enum InvoiceReportFields {
  amount,
  balance,
  client,
  status,
  number,
  discount,
  po_number,
  date,
  due_date,
  partial,
  partial_due_date,
  auto_bill,
  custom_value_1,
  custom_value_2,
  custom_value_3,
  custom_value_4,
  custom_taxes_1,
  custom_taxes_2,
  custom_taxes_3,
  custom_taxes_4,
  has_expenses,
  custom_surcharge_1,
  custom_surcharge_2,
  custom_surcharge_3,
  custom_surcharge_4,
  updated_at,
  archived_at,
  is_deleted,
}

var memoizedInvoiceReport = memo6((
  UserCompanyEntity userCompany,
  ReportsUIState reportsUIState,
  BuiltMap<String, InvoiceEntity> invoiceMap,
  BuiltMap<String, ClientEntity> clientMap,
  BuiltMap<String, UserEntity> userMap,
  StaticState staticState,
) =>
    invoiceReport(userCompany, reportsUIState, invoiceMap, clientMap, userMap,
        staticState));

ReportResult invoiceReport(
  UserCompanyEntity userCompany,
  ReportsUIState reportsUIState,
  BuiltMap<String, InvoiceEntity> invoiceMap,
  BuiltMap<String, ClientEntity> clientMap,
  BuiltMap<String, UserEntity> userMap,
  StaticState staticState,
) {
  final List<List<ReportElement>> data = [];
  BuiltList<InvoiceReportFields> columns;

  final reportSettings = userCompany.settings.reportSettings;
  final invoiceReportSettings =
      reportSettings != null && reportSettings.containsKey(kReportInvoice)
          ? reportSettings[kReportInvoice]
          : ReportSettingsEntity();

  if (invoiceReportSettings.columns.isNotEmpty) {
    columns = BuiltList(invoiceReportSettings.columns
        .map((e) => EnumUtils.fromString(InvoiceReportFields.values, e))
        .toList());
  } else {
    columns = BuiltList(<InvoiceReportFields>[
      InvoiceReportFields.number,
      InvoiceReportFields.amount,
      InvoiceReportFields.balance,
      InvoiceReportFields.date,
      InvoiceReportFields.due_date,
      InvoiceReportFields.client
    ]);
  }

  for (var invoiceId in invoiceMap.keys) {
    final invoice = invoiceMap[invoiceId];
    final client = clientMap[invoice.clientId];
    if (invoice.isDeleted) {
      continue;
    }

    bool skip = false;
    final List<ReportElement> row = [];

    for (var column in columns) {
      dynamic value = '';

      switch (column) {
        case InvoiceReportFields.amount:
          value = invoice.amount;
          break;
        case InvoiceReportFields.balance:
          value = invoice.balance;
          break;
        case InvoiceReportFields.client:
          value = client?.listDisplayName ?? '';
          break;
        case InvoiceReportFields.status:
          value = staticState.invoiceStatusMap[invoice.statusId]?.name ?? '';
          break;
        case InvoiceReportFields.number:
          value = invoice.number;
          break;
        case InvoiceReportFields.discount:
          value = invoice.discount;
          break;
        case InvoiceReportFields.po_number:
          value = invoice.poNumber;
          break;
        case InvoiceReportFields.date:
          value = invoice.date;
          break;
        case InvoiceReportFields.due_date:
          value = invoice.dueDate;
          break;
        case InvoiceReportFields.partial:
          value = invoice.partial;
          break;
        case InvoiceReportFields.partial_due_date:
          value = invoice.partialDueDate;
          break;
        case InvoiceReportFields.auto_bill:
          value = invoice.autoBill;
          break;
        case InvoiceReportFields.custom_value_1:
          value = invoice.customValue1;
          break;
        case InvoiceReportFields.custom_value_2:
          value = invoice.customValue2;
          break;
        case InvoiceReportFields.custom_value_3:
          value = invoice.customValue3;
          break;
        case InvoiceReportFields.custom_value_4:
          value = invoice.customValue4;
          break;
        case InvoiceReportFields.custom_taxes_1:
          value = invoice.customTaxes1;
          break;
        case InvoiceReportFields.custom_taxes_2:
          value = invoice.customTaxes2;
          break;
        case InvoiceReportFields.custom_taxes_3:
          value = invoice.customTaxes3;
          break;
        case InvoiceReportFields.custom_taxes_4:
          value = invoice.customTaxes4;
          break;
        case InvoiceReportFields.has_expenses:
          value = invoice.hasExpenses;
          break;
        case InvoiceReportFields.custom_surcharge_1:
          value = invoice.customSurcharge1;
          break;
        case InvoiceReportFields.custom_surcharge_2:
          value = invoice.customSurcharge2;
          break;
        case InvoiceReportFields.custom_surcharge_3:
          value = invoice.customSurcharge3;
          break;
        case InvoiceReportFields.custom_surcharge_4:
          value = invoice.customSurcharge4;
          break;
        case InvoiceReportFields.updated_at:
          value = convertTimestampToDateString(invoice.createdAt);
          break;
        case InvoiceReportFields.archived_at:
          value = convertTimestampToDateString(invoice.createdAt);
          break;
        case InvoiceReportFields.is_deleted:
          value = invoice.isDeleted;
          break;
      }

      if (!ReportResult.matchField(
        value: value,
        userCompany: userCompany,
        reportsUIState: reportsUIState,
        column: EnumUtils.parse(column),
      )) {
        skip = true;
      }

      if (value.runtimeType == bool) {
        row.add(invoice.getReportBool(value: value));
      } else if (value.runtimeType == double) {
        row.add(invoice.getReportNumber(
            value: value, currencyId: client.settings.currencyId));
      } else {
        row.add(invoice.getReportString(value: value));
      }
    }

    if (!skip) {
      data.add(row);
    }
  }

  data.sort((rowA, rowB) {
    if (rowA.length <= invoiceReportSettings.sortIndex ||
        rowB.length <= invoiceReportSettings.sortIndex) {
      return 0;
    }

    final String valueA = rowA[invoiceReportSettings.sortIndex].value;
    final String valueB = rowB[invoiceReportSettings.sortIndex].value;

    if (invoiceReportSettings.sortAscending) {
      return valueA.compareTo(valueB);
    } else {
      return valueB.compareTo(valueA);
    }
  });

  return ReportResult(
    allColumns:
        InvoiceReportFields.values.map((e) => EnumUtils.parse(e)).toList(),
    columns: columns.map((item) => EnumUtils.parse(item)).toList(),
    data: data,
  );
}
