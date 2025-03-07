// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:timeago/timeago.dart' as timeago;

// Project imports:
import 'package:invoiceninja_flutter/ui/app/help_text.dart';
import 'package:invoiceninja_flutter/ui/app/lists/list_divider.dart';
import 'package:invoiceninja_flutter/ui/app/loading_indicator.dart';
import 'package:invoiceninja_flutter/ui/app/scrollable_listview.dart';
import 'package:invoiceninja_flutter/ui/invoice/view/invoice_view_vm.dart';
import 'package:invoiceninja_flutter/utils/formatting.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';

class InvoiceViewHistory extends StatefulWidget {
  const InvoiceViewHistory({Key key, @required this.viewModel})
      : super(key: key);

  final AbstractInvoiceViewVM viewModel;

  @override
  _InvoiceViewHistoryState createState() => _InvoiceViewHistoryState();
}

class _InvoiceViewHistoryState extends State<InvoiceViewHistory> {
  @override
  void didChangeDependencies() {
    if (widget.viewModel.invoice.isStale) {
      widget.viewModel.onRefreshed(context);
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final invoice = viewModel.invoice;

    // TODO remove this null check, it shouldn't be needed
    if (invoice.isStale || invoice.history == null) {
      return LoadingIndicator();
    }

    final activityList = invoice.activities
        .where((activity) => activity.history != null)
        .toList();
    activityList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (activityList.isEmpty) {
      return HelpText(AppLocalization.of(context).noHistory);
    }

    return ScrollableListViewBuilder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemBuilder: (BuildContext context, index) {
        final activity = activityList[index];
        final history = activity.history;
        final user = viewModel.state.userState.get(activity.userId);

        return ListTile(
          title: Text(
            formatNumber(history.amount, context, clientId: invoice.clientId) +
                ' • ' +
                user.listDisplayName,
          ),
          subtitle: Text(formatDate(
                convertTimestampToDateString(history.createdAt),
                context,
                showTime: true,
              ) +
              ' • ' +
              timeago.format(convertTimestampToDate(history.createdAt))),
          trailing: Icon(Icons.chevron_right),
          onTap: () =>
              viewModel.onViewPdf(context, invoice, history.activityId),
        );
      },
      separatorBuilder: (context, index) => ListDivider(),
      itemCount: invoice.history.length,
    );
  }
}
