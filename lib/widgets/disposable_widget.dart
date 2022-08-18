import 'dart:async';

class DisposableWidget {
  final List<StreamSubscription> _subscriptions = [];

  void cancelSubscriptions() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
  }

  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }
}

extension DisposableStreamSubscriton on StreamSubscription {
  void canceledBy(DisposableWidget widget) {
    widget.addSubscription(this);
  }
}
