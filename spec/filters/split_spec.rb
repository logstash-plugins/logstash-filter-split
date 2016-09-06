# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/filters/split"
require "logstash/event"

describe LogStash::Filters::Split do

  describe "all defaults" do
    config <<-CONFIG
      filter {
        split { }
      }
    CONFIG

    sample "big\nbird\nsesame street" do
      insist { subject.length } == 3
      insist { subject[0]["message"] } == "big"
      insist { subject[1]["message"] } == "bird"
      insist { subject[2]["message"] } == "sesame street"
    end
  end

  describe "custome terminator" do
    config <<-CONFIG
      filter {
        split {
          terminator => "\t"
        }
      }
    CONFIG

    sample "big\tbird\tsesame street" do
      insist { subject.length } == 3
      insist { subject[0]["message"] } == "big"
      insist { subject[1]["message"] } == "bird"
      insist { subject[2]["message"] } == "sesame street"
    end
  end

  describe "merge object with root" do
    config <<-CONFIG
      filter {
        split {
          field => "events"
          merge_hash => true
        }
      }
    CONFIG

    sample("still_here" => true, "events" => [{"id" => 2, "user" => "frank"}]) do
      insist { subject.get("still_here") } == true
      insist { subject.get("id") } == 2
      insist { subject.get("user") } == "frank"
      insist { subject.get("events") } == [{"id" => 2, "user" => "frank"}]
    end
  end

  describe "delete field" do
    config <<-CONFIG
      filter {
        split {
          field => "in"
          target => "out"
          delete_field => true
        }
      }
    CONFIG

    sample("in" => "one\ntwo") do
      insist { subject[0].get("out") } == "one"
      insist { subject[1].get("out") } == "two"
      insist { subject[0].get("in") } == nil
      insist { subject[1].get("in") } == nil
    end
  end

  describe "try to delete target field" do
    config <<-CONFIG
      filter {
        split {
          field => "in"
          target => "in"
          delete_field => true
        }
      }
    CONFIG

    sample("in" => "one\ntwo") do
      insist { subject[0].get("in") } == "one"
      insist { subject[1].get("in") } == "two"
    end
  end

  describe "merge object with root and delete field" do
    config <<-CONFIG
      filter {
        split {
          field => "events"
          merge_hash => true
          delete_field => true
        }
      }
    CONFIG

    sample("still_here" => true, "events" => [{"id" => 2, "user" => "frank"}]) do
      insist { subject.get("still_here") } == true
      insist { subject.get("id") } == 2
      insist { subject.get("events") } == nil
    end
  end

  describe "merge object with target and try to delete target field" do
    config <<-CONFIG
      filter {
        split {
          field => "events"
          target => "events"
          merge_hash => true
          delete_field => true
        }
      }
    CONFIG

    sample("events" => [{"id" => 2}]) do
      insist { subject.get("events") } == {"id" => 2}
    end
  end

  describe "merge object with target field" do
    config <<-CONFIG
      filter {
        split {
          field => "events"
          merge_hash => true
          target => "user"
        }
      }
    CONFIG

    sample("still_here" => true, "user" => {"id" => 3, "visits" => 10}, "events" => [{"id" => 2, "user" => "frank"}]) do
      insist { subject.get("still_here") } == true
      insist { subject.get("id") } == nil
      insist { subject.get("user") } == {"id" => 2, "visits" => 10, "user" => "frank"}
      insist { subject.get("events") } == [{"id" => 2, "user" => "frank"}]
    end
  end

  describe "merge string as hash" do
    config <<-CONFIG
      filter {
        split {
          field => "events"
          merge_hash => true
        }
      }
    CONFIG

    sample("events" => ["one", "two"]) do
      insist { subject[0].get("events") } == "one"
      insist { subject[1].get("events") } == "two"
    end
  end

  describe "custom field" do
    config <<-CONFIG
      filter {
        split {
          field => "custom"
        }
      }
    CONFIG

    sample("custom" => "big\nbird\nsesame street", "do_not_touch" => "1\n2\n3") do
      insist { subject.length } == 3
      subject.each do |s|
         insist { s["do_not_touch"] } == "1\n2\n3"
      end
      insist { subject[0]["custom"] } == "big"
      insist { subject[1]["custom"] } == "bird"
      insist { subject[2]["custom"] } == "sesame street"
    end
  end

  describe "split array" do
    config <<-CONFIG
      filter {
        split {
          field => "array"
        }
      }
    CONFIG

    sample("array" => ["big", "bird", "sesame street"], "untouched" => "1\n2\n3") do
      insist { subject.length } == 3
      subject.each do |s|
         insist { s["untouched"] } == "1\n2\n3"
      end
      insist { subject[0]["array"] } == "big"
      insist { subject[1]["array"] } == "bird"
      insist { subject[2]["array"] } == "sesame street"
    end

    sample("array" => ["big"], "untouched" => "1\n2\n3") do
      insist { subject.is_a?(Logstash::Event) }
      insist { subject["array"] } == "big"
    end
  end

  describe "split array into new field" do
    config <<-CONFIG
      filter {
        split {
          field => "array"
          target => "element"
        }
      }
    CONFIG

    sample("array" => ["big", "bird", "sesame street"]) do
      insist { subject.length } == 3
      insist { subject[0]["element"] } == "big"
      insist { subject[1]["element"] } == "bird"
      insist { subject[2]["element"] } == "sesame street"
    end
  end

  context "when invalid type is passed" do
    it "should raise exception" do
      filter = LogStash::Filters::Split.new({"field" => "field"})
      event = LogStash::Event.new("field" => 10)
      expect {filter.filter(event)}.to raise_error(LogStash::ConfigurationError)
    end
  end
end
