require 'spec_helper'

RSpec.describe Nitro::Consent::DSL do
  let(:subject) { Nitro::Consent::Subject.new(nil, nil, nil) }
  let(:defaults) { {} }
  let(:dsl) { Nitro::Consent::DSL.new(subject, defaults) }

  describe '.build' do
    it 'builds the subject through the DSL' do
      context_object = nil

      Nitro::Consent::DSL.build subject do
        context_object = self
      end

      expect(context_object).to be_a(Nitro::Consent::DSL)
    end

    it 'builds defines the defaults' do
      context_defaults = nil

      Nitro::Consent::DSL.build subject, default: :whatever do
        context_defaults = @defaults
      end

      expect(context_defaults).to eql(default: :whatever)
    end
  end

  describe '#view' do
    it 'adds a view to the subject' do
      dsl.view :view_key, 'View YEY'

      expect(subject.views[:view_key].label).to eql 'View YEY'
    end

    it 'accepts a block for conditions' do
      dsl.view :view_key, 'View YEY' do |user|
        { id: user.id }
      end

      user = double(id: 10)
      expect(subject.views[:view_key].conditions(user)).to eql(id: user.id)
    end
  end

  describe '#eval_view' do
    it 'accepts a conditions string for eval' do
      dsl.eval_view :view_key, 'View YEY', '{object: 1}'

      expect(subject.views[:view_key].conditions(nil)).to eql(object: 1)
    end

    it 'is a view that evaluate the condition as ruby with the user variable' do
      user = double(id: 1)

      dsl.eval_view :view_key, 'View YEY', '{user: user.id}'

      expect(subject.views[:view_key].conditions(user)).to eql(user: 1)
    end
  end

  describe '#action' do
    let(:view_all) { double }
    let(:view_no_access) { double }
    before do
      subject.views[:all] = view_all
      subject.views[:no_access] = view_no_access
    end

    it 'creates the action in the subject' do
      dsl.action :action_key, 'ACTIONNNNNN'

      expect(subject.actions[:action_key].label).to eql 'ACTIONNNNNN'
    end

    it 'creates the action with views' do
      dsl.action :action_key, 'ACTIONNNNNN', views: [:all]

      expect(subject.actions[:action_key].views).to eql [view_all]
    end

    it 'creates the action in the with context defaults' do
      defaults[:views] = [:all]

      dsl.action :action_key, 'ACTIONNNNNN'

      expect(subject.actions[:action_key].views).to eql [view_all]
    end

    it 'sets the action subject' do
      dsl.action :action_key, 'ACTIONNNNNN'

      expect(subject.actions[:action_key].subject).to be subject
    end

    it 'allows to override defaults' do
      defaults[:views] = [:all]

      dsl.action :action_key, 'ACTIONNNNNN', views: [:no_access]

      expect(subject.actions[:action_key].views).to eql [view_no_access]
    end
  end

  describe '#with_defaults' do
    it 'creates a new DSL context with merged defaults' do
      defaults[:foo] = 'bar'

      block = -> (_, __) {}
      expected_defaults = { lol: 'rofl', foo: 'bar' }
      expect(Nitro::Consent::DSL).to receive(:build)
        .with(subject, expected_defaults, &block)

      dsl.with_defaults lol: 'rofl', &block
    end
  end
end
