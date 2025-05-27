# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoPercent::BulkProcessor do
  before do
    allow(TwoPercent::CreateEvent).to receive(:create)
    allow(TwoPercent::ReplaceEvent).to receive(:create)
    allow(TwoPercent::DeleteEvent).to receive(:create)
  end
  let(:stub_handler) { double("EventHandler", dispatch: nil) }

  it "dispatches each operation to the event handler" do
    operations = [
      Factory.bulk_operation(method: "POST", path: "/Users", data: {
                               name: { givenName: "Smith", familyName: "Berry" },
                               userName: "smith",
                             }),
      Factory.bulk_operation(method: "POST", path: "/Users", data: {
                               userName: "Kim",
                               password: "kim123",
                               name: { givenName: "Kim", familyName: "Berry" },
                             }),
    ]

    TwoPercent::BulkProcessor.new(operations).dispatch(stub_handler)

    expect(stub_handler).to(
      have_received(:dispatch).with("POST", resource: "Users", params: {
                                      name: { givenName: "Smith", familyName: "Berry" },
                                      userName: "smith",
                                    })
    )

    expect(stub_handler).to(
      have_received(:dispatch).with("POST", resource: "Users", params: {
                                      name: { givenName: "Kim", familyName: "Berry" },
                                      userName: "Kim",
                                      password: "kim123",
                                    })
    )
  end
end
