/// A signature for a then function for a [pipeline].
typedef PipelineThen<T extends Object> = void Function(T subject);

/// A pipeline handler.
abstract class PipelineHandler<T extends Object> {
  /// Process the subject.
  void handle(T subject, void Function(T subject) next);
}

/// Process the [subject] through [handlers] and call [then] with the result.
void pipeline<T extends Object>(
  T subject,
  List<PipelineHandler>? handlers,
  PipelineThen<T> then,
) {
  _run(subject, handlers, then, 0);
}

void _run<T extends Object>(
  T subject,
  List<PipelineHandler>? pipes,
  PipelineThen<T> then,
  int index,
) {
  if (pipes == null || index >= pipes.length) {
    then(subject);

    return;
  }

  pipes.elementAt(index).handle(subject, (subject) {
    _run<T>(subject as T, pipes, then, index + 1);
  });
}
