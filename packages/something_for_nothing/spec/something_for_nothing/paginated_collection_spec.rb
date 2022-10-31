# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SomethingForNothing::PaginatedCollection do
  let(:builder) { double }
  let(:records) { [] }
  let(:paginatable) { double(paginate: records) }
  let(:total_entries) { 10 }
  let(:total_pages) { 10 }
  let(:current_page) { 20 }

  before do
    allow(builder).to receive(:new) { double }
    allow(records).to receive(:total_entries) { total_entries }
    allow(records).to receive(:total_pages) { total_pages }
    allow(records).to receive(:current_page) { current_page }
  end

  subject do
    SomethingForNothing::PaginatedCollection.new(builder, paginatable)
  end

  it { expect(subject).to respond_to :current_page }
  it { expect(subject).to respond_to :total_pages }
  it { expect(subject).to be_a Array }

  it 'returns a list with the same records that it receive' do
    expect(subject).to eql records
  end

  context 'when paginating' do
    it 'set total_pages' do
      expect(subject.total_pages).to eql total_pages
    end

    it 'set current_page' do
      expect(subject.current_page).to eql current_page
    end
  end
end
