#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require './bin/output-traincartable'

class OutputTrainCartableTest < Minitest::Test
  # 1本の列車の1駅の時刻表
  def test_make_timetable_of_train_at_a_station
    sample_at_mikunigaoka = TrainCarTable::TimetableOfTrainAtAStation.new("J121-1", "三国が丘", "10:00:00", "10:01:00")
    assert_equal "J121-1", sample_at_mikunigaoka.train_id
    assert_equal "J121", sample_at_mikunigaoka.train_number
    assert_equal "三国が丘", sample_at_mikunigaoka.station_name
    assert sample_at_mikunigaoka.arrival_time.time_defined?
    assert sample_at_mikunigaoka.departure_time.time_defined?
    assert_equal TrainCarTable::TrainTime.new("10:00:00"), sample_at_mikunigaoka.arrival_time
    assert_equal TrainCarTable::TrainTime.new("10:01:00"), sample_at_mikunigaoka.departure_time
    refute sample_at_mikunigaoka.origin_station?
    refute sample_at_mikunigaoka.destination_station?
    refute sample_at_mikunigaoka.pass_this_station?

    sample_at_chikushi_start = TrainCarTable::TimetableOfTrainAtAStation.new("4050-1", "筑紫", nil, "05:13:00")
    refute sample_at_chikushi_start.arrival_time.time_defined?
    assert sample_at_chikushi_start.departure_time.time_defined?
    assert_equal TrainCarTable::TrainTime.new("05:13:00"), sample_at_chikushi_start.departure_time
    assert sample_at_chikushi_start.origin_station?
    refute sample_at_chikushi_start.destination_station?
    refute sample_at_chikushi_start.pass_this_station?

    sample_at_fukuoka_end = TrainCarTable::TimetableOfTrainAtAStation.new("4050-1", "西鉄福岡(天神)", "05:46:00", nil)
    assert_equal TrainCarTable::TrainTime.new("05:46:00"), sample_at_fukuoka_end.arrival_time
    refute sample_at_fukuoka_end.departure_time.time_defined?
    refute sample_at_fukuoka_end.origin_station?
    assert sample_at_fukuoka_end.destination_station?
    refute sample_at_fukuoka_end.pass_this_station?

    sample_at_passage_station = TrainCarTable::TimetableOfTrainAtAStation.new("A111-1", "三国が丘", "", "")
    assert sample_at_passage_station.pass_this_station?

    assert_raises(TrainCarTable::InvalidParameterError) { TrainCarTable::TimetableOfTrainAtAStation.new("", "", "", "") }
    assert_raises(TrainCarTable::InvalidParameterError) { TrainCarTable::TimetableOfTrainAtAStation.new("FFFF-5", "", "", "") }

    assert_raises(TrainCarTable::InvalidParameterError) { TrainCarTable::TimetableOfTrainAtAStation.new("A113-1", "三国が丘", "hogehogefugafuga", "") }
  end

  # 1本の列車を表す
  def test_make_train_object
    assert_raises(TrainCarTable::FileNotFoundError) { TrainCarTable::Train.new('db20220828/weekday/none.csv') }
    train_weekday_4050_1 = TrainCarTable::Train.new('db20220828/weekday/timetable_weekday_4050-1.csv')
    assert_equal "4050-1", train_weekday_4050_1.train_id
    assert_equal "4050", train_weekday_4050_1.train_number
    assert_equal "筑紫", train_weekday_4050_1.origin.station_name
    assert_equal "西鉄福岡(天神)", train_weekday_4050_1.destination.station_name
    assert_equal TrainCarTable::TrainTime.new("05:13:00"), train_weekday_4050_1.origin.departure_time
    assert_equal TrainCarTable::TrainTime.new("05:46:00"), train_weekday_4050_1.destination.arrival_time
  end
end

