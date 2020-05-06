import 'Model/project.dart';

/// Total duration for this project. Can be accumulated from several records.
/// The total can be for whatever timeperiod the user is currently interested in.
/// So ths is "cached" data and gets frequently overwritten.
/// The Project object held here should not be modified through
/// the DurationProject object because it points to the same Project
/// Objects as is held by theSavedState.projects map.
/// Only the duration in this object should be modified through this object.
class DurationProject {
  DurationProject(this.duration, this.project);

  Duration duration;
  final Project project; // TODO can i make it final?
}