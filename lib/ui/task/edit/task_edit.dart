// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_redux/flutter_redux.dart';

// Project imports:
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/entities.dart';
import 'package:invoiceninja_flutter/data/models/task_model.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/ui/app/app_border.dart';
import 'package:invoiceninja_flutter/ui/app/edit_scaffold.dart';
import 'package:invoiceninja_flutter/ui/app/live_text.dart';
import 'package:invoiceninja_flutter/ui/task/edit/task_edit_details_vm.dart';
import 'package:invoiceninja_flutter/ui/task/edit/task_edit_times_vm.dart';
import 'package:invoiceninja_flutter/ui/task/edit/task_edit_vm.dart';
import 'package:invoiceninja_flutter/utils/formatting.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:invoiceninja_flutter/utils/platforms.dart';

class TaskEdit extends StatefulWidget {
  const TaskEdit({
    Key key,
    @required this.viewModel,
  }) : super(key: key);

  final TaskEditVM viewModel;

  @override
  _TaskEditState createState() => _TaskEditState();
}

class _TaskEditState extends State<TaskEdit>
    with SingleTickerProviderStateMixin {
  TabController _controller;
  int _updatedAt = 0;

  static final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: '_taskEdit');

  static const kDetailsScreen = 0;
  static const kTimesScreen = 1;

  @override
  void initState() {
    super.initState();

    final index =
        widget.viewModel.taskTimeIndex != null ? kTimesScreen : kDetailsScreen;

    _controller = TabController(vsync: this, length: 2, initialIndex: index);
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.viewModel.taskTimeIndex != null) {
      _controller.animateTo(kTimesScreen);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final viewModel = widget.viewModel;
    final task = viewModel.task;
    final state = viewModel.state;
    final isFullscreen = state.prefState.isEditorFullScreen(EntityType.task);

    return EditScaffold(
      isFullscreen: isFullscreen,
      entity: task,
      title: task.isNew ? localization.newTask : localization.editTask,
      onCancelPressed: (context) => viewModel.onCancelPressed(context),
      onSavePressed: (context) {
        final bool isValid = _formKey.currentState.validate();

        /*
        setState(() {
          autoValidate = !isValid ?? false;
        });
         */

        if (!isValid) {
          return;
        }

        viewModel.onSavePressed(context);
      },
      appBarBottom: TabBar(
        controller: _controller,
        //isScrollable: true,
        tabs: [
          Tab(
            text: localization.details,
          ),
          Tab(
            text: localization.times,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: isFullscreen
            ? TaskEditDetailsScreen(
                key: ValueKey('__task_${task.id}_${_updatedAt}__'))
            : TabBarView(
                key: ValueKey('__task_${task.id}_${_updatedAt}__'),
                controller: _controller,
                children: <Widget>[
                  TaskEditDetailsScreen(),
                  TaskEditTimesScreen(),
                ],
              ),
      ),
      bottomNavigationBar: _BottomBar(
        task: task,
      ),
      floatingActionButton: task.isInvoiced || task.isDeleted
          ? SizedBox()
          : FloatingActionButton(
              heroTag: 'task_edit_fab',
              backgroundColor: Theme.of(context).primaryColorDark,
              onPressed: () {
                viewModel.onFabPressed();
                setState(() {
                  _updatedAt = DateTime.now().millisecondsSinceEpoch;
                });
              },
              child: Icon(
                task.isRunning ? Icons.stop : Icons.play_arrow,
                color: Colors.white,
              ),
              tooltip: task.isRunning ? localization.stop : localization.start,
            ),
    );
  }
}

class _BottomBar extends StatefulWidget {
  const _BottomBar({
    Key key,
    @required this.task,
  }) : super(key: key);

  final TaskEntity task;

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  Timer _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(Duration(seconds: 1),
        (Timer t) => mounted ? setState(() => false) : false);
  }

  @override
  void dispose() {
    _timer.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final store = StoreProvider.of<AppState>(context);
    final state = store.state;
    final useSidebarEditor =
        state.prefState.useSidebarEditor[EntityType.task] ?? false;

    return BottomAppBar(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: CircularNotchedRectangle(),
      child: SizedBox(
        height: kTopBottomBarHeight,
        child: AppBorder(
          isTop: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDesktop(context))
                Tooltip(
                  message: useSidebarEditor
                      ? localization.fullscreenEditor
                      : localization.sidebarEditor,
                  child: InkWell(
                    onTap: () =>
                        store.dispatch(ToggleEditorLayout(EntityType.task)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(useSidebarEditor
                          ? Icons.chevron_left
                          : Icons.chevron_right),
                    ),
                  ),
                ),
              AppBorder(
                isLeft: isDesktop(context),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: LiveText(() {
                      final task = widget.task;
                      final title = localization.duration +
                          ' ' +
                          formatNumber(
                              widget.task
                                  .calculateDuration(
                                      includeRunning: task.showAsRunning)
                                  .inSeconds
                                  .toDouble(),
                              context,
                              formatNumberType: FormatNumberType.duration);
                      if (task.number.isNotEmpty) {
                        return '${task.number} • $title';
                      }

                      return title;
                    },
                        style: TextStyle(
                          color: state.prefState.enableDarkMode
                              ? Colors.white
                              : Colors.black,
                          fontSize: 20.0,
                        )),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
