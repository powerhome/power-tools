require "spec_helper"

describe OStruct::Sanitizer do
  it "has a version number" do
    expect(OStruct::Sanitizer::VERSION).not_to be nil
  end

  describe "invalid usage" do
    it "fails including OStruct::Sanitizer within a non OpenStruct class" do
      define_invalid_usage = -> {
        class InvalidUsage
          include OStruct::Sanitizer
        end
      }

      expect(define_invalid_usage).to raise_error "#{OStruct::Sanitizer.name} can only be used within OpenStruct classes"
    end
  end

  describe "#truncate" do
    class User < OpenStruct
      include OStruct::Sanitizer
      truncate :first_name, :last_name, length: 10
      truncate :middle_name, length: 3, strip_whitespaces: false
    end

    let(:user) do
      User.new(
        first_name: " first name longer than 10 characters",
        last_name: " last name longer than 10 characters",
        middle_name: " Rose ",
      )
    end

    it "truncates user's first name to 10 characters" do
      expect(user.first_name).to eq "first name"
    end

    it "truncates user's last name to 10 characters" do
      expect(user.last_name).to eq "last name"
    end

    it "truncates user's middle name without stipping whitespaces" do
      expect(user.middle_name).to eq " Ro"
    end

    it "does not sanitize if value is nil" do
      user = User.new first_name: nil, last_name: nil
      expect(user.first_name).to be nil
      expect(user.last_name).to be nil
    end
  end

  describe "#alphanumeric" do
    class User < OpenStruct
      include OStruct::Sanitizer
      alphanumeric :city, :country
    end

    let(:user) do
      User.new(
        city: "Porto, Alegre!",
        country: "B.r!_a,z#i%l^",
      )
    end

    it "drops punctuation from user's city name" do
      expect(user.city).to eq "Porto Alegre"
    end

    it "drops punctuation from user's country name" do
      expect(user.country).to eq "Brazil"
    end

    it "does not sanitize if value is nil" do
      user = User.new city: nil, country: nil
      expect(user.city).to be nil
      expect(user.country).to be nil
    end
  end

  describe "#strip" do
    class User < OpenStruct
      include OStruct::Sanitizer
      strip :email, :phone
    end

    let(:user) do
      User.new(
        email: "  drborges.cic@gmail.com   ",
        phone: "  (55) 51 00000000    ",
      )
    end

    it "strips out leading and trailing spaces from user's email" do
      expect(user.email).to eq "drborges.cic@gmail.com"
    end

    it "strips out leading and trailing spaces from user's phone number" do
      expect(user.phone).to eq "(55) 51 00000000"
    end

    it "does not sanitize if value is nil" do
      user = User.new email: nil, phone: nil
      expect(user.email).to be nil
      expect(user.phone).to be nil
    end
  end

  describe "#digits" do
    class User < OpenStruct
      include OStruct::Sanitizer
      digits :ssn, :cell_phone
    end

    let(:user) do
      User.new(
        ssn: "111-11-1111",
        cell_phone: "+1-541-000-0000",
      )
    end

    it "keeps only digits from ssn field" do
      expect(user.ssn).to eq "111111111"
    end

    it "keeps only digits from cell_phone field" do
      expect(user.cell_phone).to eq "15410000000"
    end

    it "does not sanitize if value is nil" do
      user = User.new ssn: nil, cell_phone: nil
      expect(user.ssn).to be nil
      expect(user.cell_phone).to be nil
    end
  end

  describe "#sanitize" do
    class User < OpenStruct
      include OStruct::Sanitizer
      sanitize "my ssn" do |value|
        value.to_s.gsub(/[^0-9]/, '')
      end
    end

    context "hash syntax" do
      it "applies sanitization rules using string as key" do
        user = User.new
        user["my ssn"] = "111-11-1111"
        expect(user["my ssn"]).to eq "111111111"
      end

      it "applies sanitization rules using symbol as key" do
        user = User.new
        user[:"my ssn"] = "111-11-1111"
        expect(user["my ssn"]).to eq "111111111"
      end

      it "applies sanitization rules using string as key in the constructor" do
        user = User.new "my ssn" => "111-11-1111"
        expect(user[:"my ssn"]).to eq "111111111"
      end
    end
  end
end
