class BattleshipError < StandardError; end

class InvalidCoordinateError < BattleshipError; end

class AlreadyTargetedError < BattleshipError; end