RSpec.shared_examples "an authenticated request" do
  it "will render a 401 status when not authentiated" do
    expect(TwoPercent.config).to(
      receive(:authenticate)
        .and_return(->(*) { head :unauthorized })
    )

    subject

    expect(response).to have_http_status(:unauthorized)
  end
end
