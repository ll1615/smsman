extension ListExtension<T> on List<T> {
  List<T> insertBetween(T item) {
    if (isEmpty) {
      return this;
    }

    var newList = <T>[this[0]];
    for (int i = 1; i < length; i++) {
      newList.add(item);
      newList.add(this[i]);
    }

    return newList;
  }
}
