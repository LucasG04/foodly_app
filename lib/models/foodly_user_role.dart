enum FoodlyUserRole {
  admin('admin'),
  moderator('moderator'),
  user('user');

  const FoodlyUserRole(this.value);
  final String value;

  @override
  String toString() => value;
}
