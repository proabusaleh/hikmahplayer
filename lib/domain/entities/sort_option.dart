import 'package:equatable/equatable.dart';

enum SortOption { title, dateAdded, duration, size }

enum SortDirection { ascending, descending }

extension SortDirectionX on SortDirection {
  bool get isAscending => this == SortDirection.ascending;
  SortDirection get toggled => isAscending ? SortDirection.descending : SortDirection.ascending;
}

class SortConfig extends Equatable {
  const SortConfig({this.option = SortOption.title, this.direction = SortDirection.ascending});

  final SortOption option;
  final SortDirection direction;

  SortConfig copyWith({SortOption? option, SortDirection? direction}) =>
      SortConfig(option: option ?? this.option, direction: direction ?? this.direction);

  @override
  List<Object?> get props => [option, direction];
}
