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

    sample("array" => ["single-element"], "untouched" => "1\n2\n3") do
      insist { subject["array"] } == "single-element"
      insist { subject["untouched"] } == "1\n2\n3"
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
      expect {filter.filter(event)}.to raise_error
    end
  end
end
