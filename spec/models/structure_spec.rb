require 'spec_helper'
require 'support/structural_metadata_helper'

module Ddr::Models
  RSpec.describe Structure, type: :model, structural_metadata: true do

    describe "#files" do
      let(:structure) { FactoryGirl.build(:simple_structure)}
      it "returns a hash of structure files" do
        expect(structure.files.keys).to match_array([ 'abc', 'def', 'ghi' ])
        structure.files.values.each do |value|
          expect(value).to be_a(Structures::File)
        end
      end
    end

    describe "#creator" do
      describe "structure has a metsHdr" do
        let(:structure) { FactoryGirl.build(:simple_structure) }
        it "returns the creator" do
          expect(structure.creator).to eq("Sam Spade")
        end
      end
      describe "structure does not have a metsHdr" do
        let(:structure) { FactoryGirl.build(:multiple_struct_maps_structure) }
        it "returns the creator" do
          expect(structure.creator).to be nil
        end
      end
    end

    describe "#repository_maintained?" do
      let(:structure) { FactoryGirl.build(:simple_structure)}
      before do
        allow(structure).to receive(:creator) { creator }
      end
      describe "maintained by the repository" do
        let(:creator) { Ddr::Models::Structures::Agent::NAME_REPOSITORY_DEFAULT }
        it "is true" do
          expect(structure.repository_maintained?).to be true
        end
      end
      describe "not maintained by the repository" do
        let(:creator) { 'foo' }
        it "is false" do
          expect(structure.repository_maintained?).to be false
        end
      end
    end

    describe "#dereferenced_structure" do
      let(:structure) { FactoryGirl.build(:nested_structure) }
      let(:expected) { nested_structure_dereferenced_hash }
      before do
        flocat_x = instance_double("Structures::FLocat", effective_use: 'foo')
        flocat_y = instance_double("Structures::FLocat", effective_use: 'bar')
        flocat_z = instance_double("Structures::FLocat", effective_use: 'baz')
        file_a = instance_double("Structures::File", repo_ids: [ 'test:7' ], flocats: [ flocat_x ])
        file_b = instance_double("Structures::File", repo_ids: [ 'test:8' ], flocats: [ flocat_y ])
        file_c = instance_double("Structures::File", repo_ids: [ 'test:9' ], flocats: [ flocat_z ])
        allow(Structures::File).to receive(:find).with(an_instance_of(Ddr::Models::Structure), 'abc') { file_a }
        allow(Structures::File).to receive(:find).with(an_instance_of(Ddr::Models::Structure), 'def') { file_b }
        allow(Structures::File).to receive(:find).with(an_instance_of(Ddr::Models::Structure), 'ghi') { file_c }
      end
      it "returns the dereferenced structure" do
        expect(structure.dereferenced_structure).to eq(expected)
      end
    end

  end
end
