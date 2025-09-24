# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoPercent::EventHandler do
  before do
    allow(TwoPercent::CreateEvent).to receive(:create)
    allow(TwoPercent::ReplaceEvent).to receive(:create)
    allow(TwoPercent::DeleteEvent).to receive(:create)
  end

  it "dispatches CreateEvent for the POST operations" do
    TwoPercent::EventHandler.dispatch("POST",
                                      resource: "Users",
                                      params: {
                                        name: {
                                          givenName: "Smith",
                                          familyName: "Berry",
                                        },
                                        userName: "smith",
                                      })

    expect(TwoPercent::CreateEvent).to(
      have_received(:create).with(
        resource: "Users",
        params: {
          name: {
            givenName: "Smith",
            familyName: "Berry",
          },
          userName: "smith",
        }
      )
    )
  end

  it "dispatches CreateEvent for the POST operations" do
    TwoPercent::EventHandler.dispatch("PUT",
                                      resource: "Users",
                                      id: "123",
                                      params: {
                                        name: {
                                          givenName: "Smith",
                                          familyName: "Berry",
                                        },
                                        userName: "smith",
                                      })

    expect(TwoPercent::ReplaceEvent).to(
      have_received(:create).with(
        resource: "Users",
        id: "123",
        params: {
          name: {
            givenName: "Smith",
            familyName: "Berry",
          },
          userName: "smith",
        }
      )
    )
  end

  it "dispatches DeleteEvent for the DELETE operations" do
    TwoPercent::EventHandler.dispatch("DELETE",
                                      resource: "Users",
                                      id: "123")

    expect(TwoPercent::DeleteEvent).to(
      have_received(:create).with(
        resource: "Users",
        id: "123"
      )
    )
  end
end
