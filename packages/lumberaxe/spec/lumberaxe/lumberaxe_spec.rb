# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lumberaxe, type: :request do
  context "with a standard request" do
    subject do
      post "/campgrounds", params: { campground: { name: "Cloudland Canyon" }, format: :json }
    end

    it "tags request_id" do
      expect { subject }.to output(/"request_id":/).to_stdout_from_any_process
    end

    it "tags IP" do
      expect { subject }.to output(/"IP":/).to_stdout_from_any_process
    end

    it "contains the defined progname" do
      expect { subject }.to output(/"progname":"app"/).to_stdout_from_any_process
    end

    it "contains message key/value pairs" do
      expect { subject }.to output(/"message":/).to_stdout_from_any_process
    end

    it "logs HTTP requests" do
      expect { subject }.to output(%r{"method":"POST","path":"/campgrounds"}).to_stdout_from_any_process
    end

    it "logs any params" do
      expect { subject }.to output(/"params":{"campground":{"name":"Cloudland Canyon"}/).to_stdout_from_any_process
    end

    it "logs anything passed to the rails logger" do
      expect { subject }.to output(/Creating campground named Cloudland Canyon/).to_stdout_from_any_process
    end

    it "logs DB requests" do
      expect { subject }.to output(/INSERT INTO/).to_stdout_from_any_process
    end

    it "logs error response" do
      expect do
        post "/campgrounds", params: { campground: { name: nil } }
      end.to output(/"status":422/).to_stdout_from_any_process
    end
  end

  context "#puma_formatter" do
    subject do
      Lumberaxe.puma_formatter.call("test log message")
    end

    it "returns log message" do
      expect(subject).to include("test log message")
    end
  end

  context "LoggerSilence" do
    it "silences as expected" do
      expect(Rails.logger.silence { "test_silencer" }).to eq("test_silencer")
    end
  end

  context "tagged logging" do
    subject do
      Lumberaxe::Logger.new(progname: "tagged_logging")
    end

    it "logs the message" do
      expect do
        subject.tagged("rose") { subject.info("bud") }
      end.to output(/"message":"bud"/).to_stdout_from_any_process
    end

    it "logs tags" do
      expect do
        subject.tagged("hot", "sour") { subject.info("soup") }
      end.to output(/"tags":\["hot","sour"\]/).to_stdout_from_any_process
    end

    it "logs tags as named keys" do
      expect do
        subject.tagged("evel=knievel") { subject.info("parachute") }
      end.to output(/"evel":"knievel"/).to_stdout_from_any_process
    end

    it "logs hash tags" do
      expect do
        subject.tagged(hash: "alton") { subject.info("brown") }
      end.to output(/"tags":\[{"hash":"alton"}\]/).to_stdout_from_any_process
    end

    it "logs any valid combination of tag formats" do
      expect do
        subject.tagged("omega", "pV=nRT", paink: "iller") { subject.info("brown") }
      end.to output(%r{(?=.*"tags":\["omega",{"paink":"iller"}\])(?=.*"pV":"nRT")}).to_stdout_from_any_process
    end
  end
end
