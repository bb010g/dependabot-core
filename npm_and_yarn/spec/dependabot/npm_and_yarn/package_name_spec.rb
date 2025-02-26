# frozen_string_literal: true

require "spec_helper"
require "dependabot/npm_and_yarn/package_name"

RSpec.describe Dependabot::NpmAndYarn::PackageName do
  describe "initialization" do
    it "raises a meaningful error if the input is not a valid package name" do
      expect { described_class.new("🤷") }.to raise_error(described_class::InvalidPackageName)
      expect { described_class.new([]) }.to raise_error(described_class::InvalidPackageName)
      expect { described_class.new({}) }.to raise_error(described_class::InvalidPackageName)
      expect { described_class.new(nil) }.to raise_error(described_class::InvalidPackageName)
      expect { described_class.new("") }.to raise_error(described_class::InvalidPackageName)
      expect { described_class.new(" prefixed-with-a-space") }.to raise_error(described_class::InvalidPackageName)
      expect { described_class.new(".prefixed-with-a-dot") }.to raise_error(described_class::InvalidPackageName)
      expect { described_class.new("!invalid") }.to raise_error(described_class::InvalidPackageName)
    end
  end

  describe "#to_s" do
    it "returns the name when no scope is present" do
      jquery = "jquery"

      package_name = described_class.new(jquery).to_s

      expect(package_name).to eq(jquery)
    end

    it "returns the name with scope when a scope is present" do
      babel_core = "@babel/core"

      package_name_with_scope = described_class.new(babel_core).to_s

      expect(package_name_with_scope).to eq(babel_core)
    end
  end

  describe "#types_package_name" do
    it "returns the corresponding types package name" do
      lodash       = "lodash"
      lodash_types = "@types/lodash"

      types_package_name = described_class.new(lodash).types_package_name

      expect(types_package_name.to_s).to eq(lodash_types)
    end

    it "returns self if it is already a types package" do
      stereo_types = "@types/stereo"

      types_package_name = described_class.new(stereo_types).types_package_name

      expect(types_package_name.to_s).to eq(stereo_types)
    end

    context "when given a scoped dependency name" do
      it "returns the corresponding scoped types package name" do
        babel_core       = "@babel/core"
        babel_core_types = "@types/babel__core"

        types_package_name = described_class.new(babel_core).types_package_name

        expect(types_package_name.to_s).to eq(babel_core_types)
      end
    end
  end

  describe "#library_name" do
    it "returns self if it is not a types package" do
      jquery = "jquery"

      library_name = described_class.new(jquery).library_name.to_s

      expect(library_name).to eq(jquery)
    end

    it "returns the corresponding library for a types package" do
      lodash_types = "@types/lodash"
      lodash       = "lodash"

      library_name = described_class.new(lodash_types).library_name

      expect(library_name.to_s).to eq(lodash)
    end

    context "when it is a scoped types package" do
      it "returns the type packages scoped name" do
        babel_core_types = "@types/babel__core"
        babel_core       = "@babel/core"

        library_name = described_class.new(babel_core_types).library_name

        expect(library_name.to_s).to eq(babel_core)
      end
    end
  end

  describe "#eql?" do
    it "compares the string representation of the package name" do
      package       = described_class.new("package")
      package_again = described_class.new("package")

      equality_check = package.eql?(package_again)

      expect(equality_check).to be true
    end

    it "returns true for equivalent package names" do
      react       = described_class.new("react")
      react_again = described_class.new("react")

      equality_check = react.eql?(react_again)

      expect(equality_check).to be true
    end

    it "returns false for non-equivalent package names" do
      react = described_class.new("react")
      vue   = described_class.new("vue")

      equality_check = react.eql?(vue)

      expect(equality_check).to be false
    end
  end

  describe "#<=>" do
    it "provides affordances for sorting/comparison" do
      first  = described_class.new("first")
      second = described_class.new("second")
      third  = described_class.new("third")

      expect([third, second, first].sort).to eq([first, second, third])
    end

    it "ignores case" do
      package_name_string = "jquery"
      all_caps  = described_class.new(package_name_string.upcase)
      all_lower = described_class.new(package_name_string.downcase)

      expect(all_lower <=> all_caps).to be_zero
    end

    it "allows for comparison with types packages" do
      library = described_class.new("my-library")

      expect([library, library.types_package_name].sort).
        to eq([library.types_package_name, library])
    end
  end
end
