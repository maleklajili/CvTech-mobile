enum Vote { up, down, neutre }

extension VoteExtension on Vote? {
  bool get isUp => this == Vote.up;
  bool get isDown => this == Vote.down;
  bool get isNeutre => this == Vote.neutre;
}
