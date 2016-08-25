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
      insist { subject[0].get("message") } == "big"
      insist { subject[1].get("message") } == "bird"
      insist { subject[2].get("message") } == "sesame street"
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
      insist { subject[0].get("message") } == "big"
      insist { subject[1].get("message") } == "bird"
      insist { subject[2].get("message") } == "sesame street"
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
         insist { s.get("do_not_touch") } == "1\n2\n3"
      end
      insist { subject[0].get("custom") } == "big"
      insist { subject[1].get("custom") } == "bird"
      insist { subject[2].get("custom") } == "sesame street"
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
         insist { s.get("untouched") } == "1\n2\n3"
      end
      insist { subject[0].get("array") } == "big"
      insist { subject[1].get("array") } == "bird"
      insist { subject[2].get("array") } == "sesame street"
    end

    sample("array" => ["single-element"], "untouched" => "1\n2\n3") do
      insist { subject.get("array") } == "single-element"
      insist { subject.get("untouched") } == "1\n2\n3"
    end
  end

  describe "split array with string interpolation" do
    config <<-CONFIG
      filter {
        split {
          field => "%{array_field}"
        }
      }
    CONFIG

    sample("array" => ["big", "bird", "sesame street"], "array_field" => "array", "untouched" => "1\n2\n3") do
      insist { subject.length } == 3
      subject.each do |s|
         insist { s.get("untouched") } == "1\n2\n3"
      end
      insist { subject[0].get("array") } == "big"
      insist { subject[1].get("array") } == "bird"
      insist { subject[2].get("array") } == "sesame street"
    end

    sample("array" => ["single-element"], "array_field" => "array", "untouched" => "1\n2\n3") do
      insist { subject.get("array") } == "single-element"
      insist { subject.get("untouched") } == "1\n2\n3"
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
      insist { subject[0].get("element") } == "big"
      insist { subject[1].get("element") } == "bird"
      insist { subject[2].get("element") } == "sesame street"
    end
  end

  describe "split array into new field with string interpolation" do
    config <<-CONFIG
      filter {
        split {
          field => "array"
          target => "%{target_field}"
        }
      }
    CONFIG

    sample("array" => ["big", "bird", "sesame street"], "target_field" => "final") do
      insist { subject.length } == 3
      insist { subject[0].get("final") } == "big"
      insist { subject[1].get("final") } == "bird"
      insist { subject[2].get("final") } == "sesame street"
    end
  end


  context "when invalid type is passed" do
    let(:filter) { LogStash::Filters::Split.new({"field" => "field"}) }
    let(:logger) { filter.logger }
    let(:event) { event = LogStash::Event.new("field" => 10) }

    before do
      allow(filter.logger).to receive(:warn).with(anything)
      filter.filter(event)
    end
    
    it "should log an error" do
      expect(filter.logger).to have_received(:warn).with(/Only String and Array types are splittable/)
    end

    it "should add a '_splitparsefailure' tag" do
      expect(event.get("tags")).to include(LogStash::Filters::Split::PARSE_FAILURE_TAG)
    end
  end
end
