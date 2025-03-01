// Package imports:
import 'package:built_collection/built_collection.dart';
import 'package:memoize/memoize.dart';

// Project imports:
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/reports/reports_state.dart';
import 'package:invoiceninja_flutter/redux/static/static_state.dart';
import 'package:invoiceninja_flutter/ui/reports/reports_screen.dart';
import 'package:invoiceninja_flutter/utils/enums.dart';
import 'package:invoiceninja_flutter/utils/formatting.dart';

enum ProductReportFields {
  id,
  name,
  price,
  description,
  cost,
  quantity,
  tax_rate1,
  tax_rate2,
  tax_rate3,
  product1,
  product2,
  product3,
  product4,
}

var memoizedProductReport = memo6((
  UserCompanyEntity userCompany,
  ReportsUIState reportsUIState,
  BuiltMap<String, ProductEntity> productMap,
  BuiltMap<String, VendorEntity> vendorMap,
  BuiltMap<String, UserEntity> userMap,
  StaticState staticState,
) =>
    productReport(userCompany, reportsUIState, productMap, vendorMap, userMap,
        staticState));

ReportResult productReport(
  UserCompanyEntity userCompany,
  ReportsUIState reportsUIState,
  BuiltMap<String, ProductEntity> productMap,
  BuiltMap<String, VendorEntity> vendorMap,
  BuiltMap<String, UserEntity> userMap,
  StaticState staticState,
) {
  final List<List<ReportElement>> data = [];
  BuiltList<ProductReportFields> columns;

  final reportSettings = userCompany.settings?.reportSettings;
  final productReportSettings =
      reportSettings != null && reportSettings.containsKey(kReportProduct)
          ? reportSettings[kReportProduct]
          : ReportSettingsEntity();

  final defaultColumns = [
    ProductReportFields.name,
    ProductReportFields.price,
    ProductReportFields.cost,
    ProductReportFields.quantity,
  ];

  if (productReportSettings.columns.isNotEmpty) {
    columns = BuiltList(productReportSettings.columns
        .map((e) => EnumUtils.fromString(ProductReportFields.values, e))
        .where((element) => element != null)
        .toList());
  } else {
    columns = BuiltList(defaultColumns);
  }

  for (var productId in productMap.keys) {
    final product = productMap[productId];

    if (product.isDeleted) {
      continue;
    }

    bool skip = false;
    final List<ReportElement> row = [];

    for (var column in columns) {
      dynamic value = '';

      switch (column) {
        case ProductReportFields.id:
          value = product.id;
          break;
        case ProductReportFields.name:
          value = product.listDisplayName;
          break;
        case ProductReportFields.price:
          value = product.price;
          break;
        case ProductReportFields.cost:
          value = product.cost;
          break;
        case ProductReportFields.description:
          value = product.notes;
          break;
        case ProductReportFields.quantity:
          value = product.quantity;
          break;
        case ProductReportFields.tax_rate1:
          value = product.taxRate1;
          break;
        case ProductReportFields.tax_rate2:
          value = product.taxRate2;
          break;
        case ProductReportFields.tax_rate3:
          value = product.taxRate3;
          break;
        case ProductReportFields.product1:
          value = product.customValue1;
          break;
        case ProductReportFields.product2:
          value = product.customValue2;
          break;
        case ProductReportFields.product3:
          value = product.customValue3;
          break;
        case ProductReportFields.product4:
          value = product.customValue4;
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
        row.add(product.getReportBool(value: value));
      } else if (column == ProductReportFields.quantity) {
        row.add(product.getReportDouble(
          value: value,
          currencyId: userCompany.company.currencyId,
          formatNumberType: FormatNumberType.double,
        ));
      } else if (value.runtimeType == double || value.runtimeType == int) {
        row.add(product.getReportDouble(
            value: value, currencyId: userCompany.company.currencyId));
      } else {
        row.add(product.getReportString(value: value));
      }
    }

    if (!skip) {
      data.add(row);
    }
  }

  final selectedColumns = columns.map((item) => EnumUtils.parse(item)).toList();
  data.sort((rowA, rowB) =>
      sortReportTableRows(rowA, rowB, productReportSettings, selectedColumns));

  return ReportResult(
    allColumns:
        ProductReportFields.values.map((e) => EnumUtils.parse(e)).toList(),
    columns: selectedColumns,
    defaultColumns:
        defaultColumns.map((item) => EnumUtils.parse(item)).toList(),
    data: data,
  );
}
