# frozen_string_literal: true

require "rails_helper"

RSpec.describe CamelTrail::Recordable do
  it "tracks creation activities" do
    truck = Truck.create! name: "Anti-alians Window", price: 1_000_000
    last_truck_history = CamelTrail.for(truck).first

    expect(last_truck_history.activity).to eql "created"
    expect(last_truck_history.source_type).to eql "Truck"
    expect(last_truck_history.source_id).to eql truck.id.to_s
    expect(last_truck_history.source_changes).to include("name" => [nil, "Anti-alians Window"],
                                                         "price" => [nil, 1_000_000])
    expect(last_truck_history.backtrace.count).to eql 3
    expect(last_truck_history.backtrace[0]).to match(%r{camel_trail/lib/camel_trail.rb:[0-9]+:in .record!.})
    expect(last_truck_history.backtrace[1]).to match(%r{camel_trail/lib/camel_trail/recordable.rb:[0-9]})
    expect(last_truck_history.backtrace[2]).to match(%r{camel_trail/spec/camel_trail/recordable_spec.rb:[0-9]})
  end

  it "tracks update activities" do
    truck = Truck.create! name: "Anti-alians Window", price: 1_000_000
    truck.update(name: "Anti-zombie Window")
    last_truck_history = CamelTrail.for(truck).first

    expect(last_truck_history.activity).to eql "updated"
    expect(last_truck_history.source_type).to eql "Truck"
    expect(last_truck_history.source_id).to eql truck.id.to_s
    expect(last_truck_history.source_changes).to include("name" => ["Anti-alians Window", "Anti-zombie Window"])
  end

  it "tracks the user id from NitroAuth.current_session" do
    truck = Truck.create! name: "Anti-alians Window", price: 1_000_000
    last_truck_history = CamelTrail.for(truck).first

    expect(last_truck_history.user_id).to eql 13
  end

  it "works fine when history_options is not passed" do
    truck = TruckWithoutHistoryOptions.create! name: "Anti-alians Window", price: 1_000_000
    last_truck_history = CamelTrail.for(truck).first

    expect(last_truck_history.activity).to eql "created"
    expect(last_truck_history.source_type).to eql "TruckWithoutHistoryOptions"
    expect(last_truck_history.source_id).to eql truck.id.to_s
    expect(last_truck_history.source_changes).to include(
      "name" => [nil, "Anti-alians Window"],
      "price" => [nil, 1_000_000]
    )
  end

  it "allows parsing the source_changes before saving" do
    truck = Truck.create! name: "Anti-alians Window", price: -1
    last_truck_history = CamelTrail.for(truck).first

    # Changed negative price to 0
    expect(last_truck_history.source_changes).to include("price" => [nil, 0])
  end

  it "does not save empty source_changes" do
    allow_any_instance_of(Truck).to receive(:saved_changes).and_return({})

    truck = Truck.create! name: "I am empty on the inside"
    last_truck_history = CamelTrail.for(truck)

    expect(last_truck_history).to eql []
  end
end
