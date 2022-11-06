#!/usr/bin/env ruby
# frozen_string_literal: true

# output-traincartable.rb
# 列車編成両数表の出力

require 'time'

module TrainCarTable
  # 管理番号 (列車番号に，車両取替前後の情報も加えたもの)
  class TrainID
    attr_reader :train_id, :train_number, :train_carchange_order

    def initialize(train_id)
      # 管理番号の形式チェック
      train_id_regexp = /([0-9ACDGHIJKL][0-9]{3})-([12])/
      regexp_results  = train_id_regexp.match(train_id)
      raise InvalidParameterError.new("Invalid Parameter: train_id = #{train_id}") if regexp_results.nil?

      @train_id = train_id
      @train_number = regexp_results[1]
      @train_carchange_order = regexp_results[2].to_i
      self.freeze
    end
  end

  # 時刻
  # Time オブジェクトを生成する
  class TrainTime
    attr_reader :time_info

    def initialize(time_str)
      if time_str.nil? || time_str == ''
        @time_info = :time_undefined
        @time_defined = false
      else
        begin
          @time_info = Time.parse(time_str)
        rescue ArgumentError
          raise InvalidParameterError.new("Invalid Parameter: Attempt parsing time_str '#{time_str}' failed.")
        end
        @time_defined = true
      end

      self.freeze
    end

    # 時刻が定義されているか
    def time_defined?
      @time_defined
    end

    # 時刻が等しいか
    def ==(other)
      other.class == self.class &&
        other.time_info == self.time_info
    end
    alias eql? ==
    def inspect
      return "TrainTime<#{time_info.strftime('%H:%M:%S')}>" if self.time_defined?

      'TrainTime<UNDEFINED>'
    end
  end

  # 列車
  class Train
    attr_reader :train_id, :train_number, :origin, :destination

    def initialize(timetable_file_path)
      raise FileNotFoundError.new("File Not Found: #{timetable_file_path}") unless File.exist?(timetable_file_path)

      @timetable_of_the_train = []
      File.open(timetable_file_path) do |f|
        f.each do |line|
          line_fields = line.chomp.split(',', -1)
          next if line_fields[0] == '管理番号'

          timetable_data_of_the_station = TimetableOfTrainAtAStation.new(line_fields[0], line_fields[2], line_fields[3], line_fields[4])
          @timetable_of_the_train << timetable_data_of_the_station
        end
      end

      timetable_of_first_station = @timetable_of_the_train.first
      timetable_of_last_station  = @timetable_of_the_train.last

      @train_id = timetable_of_first_station.train_id
      @train_number = timetable_of_first_station.train_number
      @origin = timetable_of_first_station
      @destination = timetable_of_last_station

      self.freeze
    end
  end

  # 時刻表（各列車の駅単位）
  class TimetableOfTrainAtAStation
    attr_reader :station_name, :arrival_time, :departure_time

    def initialize(train_id, station_name, arrival_time_str, departure_time_str)
      # 駅名が空でないかチェック
      raise InvalidParameterError.new('Invalid Parameter: station_name is empty.') if station_name == '' || station_name.nil?

      @station_name = station_name

      @train_id_info = TrainID.new(train_id)
      @arrival_time = TrainTime.new(arrival_time_str)
      @departure_time = TrainTime.new(departure_time_str)
      self.freeze
    end

    # 列車の起点駅かどうか
    def origin_station?
      !@arrival_time.time_defined? && @departure_time.time_defined?
    end

    # 列車の終点駅かどうか
    def destination_station?
      @arrival_time.time_defined? && !@departure_time.time_defined?
    end

    # 列車の通過駅かどうか
    ## 着発時刻がともに空 → 時刻データベースファイルが正当であると期待して通過駅とする
    ## (運行区間内であることの照合をすべきか検討)
    def pass_this_station?
      !(@arrival_time.time_defined? || @departure_time.time_defined?)
    end

    # 管理番号
    def train_id
      @train_id_info.train_id
    end

    # 列車番号
    def train_number
      @train_id_info.train_number
    end
  end

  # 運用
  class Operation
    def initialize(operation_id)
      @operation_id = operation_id
    end
  end

  class FileNotFoundError < StandardError
    def initialize(msg = "File Not Found.")
      super
    end
  end

  class MakeTimetableError < StandardError
    def initialize(msg = "Make Timetable Error: Wrong Timetable Record.")
      super
    end
  end

  class InvalidParameterError < StandardError
    def initialize(msg = "Parameter is invalid.")
      super
    end
  end
end

# ========================================================================================
# 本体
# ========================================================================================

database_directory = ARGV.shift
dia_day = ARGV.shift
train_list_file_path = ARGV.shift

File.open(train_list_file_path) do |f|
  f.each do |train_list_line|
    line_fields = train_list_line.chomp.split(',', -1)
    next if line_fields[0] == "管理番号"
  end
end
