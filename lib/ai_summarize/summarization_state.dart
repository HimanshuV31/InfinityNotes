import 'package:equatable/equatable.dart';
import 'package:infinitynotes/services/cloud/cloud_note.dart';

abstract class SummarizationState extends Equatable {}

class SummarizationInitial extends SummarizationState {
  @override
  List<Object> get props => []; // No properties to compare
}

class SummarizationLoading extends SummarizationState {
  final double? progress;
  SummarizationLoading({this.progress});

  @override
  List<Object?> get props => [progress]; // Compare progress value
}

class SummarizationSuccess extends SummarizationState {
  final String summary;
  final CloudNote originalNote;
  SummarizationSuccess({required this.summary, required this.originalNote});

  @override
  List<Object> get props => [summary, originalNote]; // Compare both values
}

class SummarizationError extends SummarizationState {
  final String error;
  SummarizationError(this.error);

  @override
  List<Object> get props => [error]; // Compare error message
}
