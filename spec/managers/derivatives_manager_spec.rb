module Ddr::Managers
  RSpec.describe DerivativesManager do

    describe "generators called" do
      before { object.add_file file, Ddr::Datastreams::CONTENT }
      context "all derivatives" do
        context "not multires_image_able" do
          let(:object) { Target.new }
          context "content is an image" do
            let(:file) { fixture_file_upload("imageA.tif", "image/tiff") }
            it "calls the thumbnail generator and not the ptif generator" do
              expect(object.derivatives).to receive(:generate_derivative).with(Ddr::Derivatives::DERIVATIVES[:thumbnail])
              expect(object.derivatives).to_not receive(:generate_derivative).with(Ddr::Derivatives::DERIVATIVES[:multires_image])
              object.derivatives.update_derivatives(:now)
            end
          end
          context "content is not an image" do
            let(:file) { fixture_file_upload("sample.docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document") }
            it "should generate neither a thumbnail nor a ptif" do
              expect(object.derivatives).to_not receive(:generate_derivative).with(Ddr::Derivatives::DERIVATIVES[:thumbnail])
              expect(object.derivatives).to_not receive(:generate_derivative).with(Ddr::Derivatives::DERIVATIVES[:multires_image])
              object.derivatives.update_derivatives(:now)
            end
          end
        end
        context "multires_image_able" do
          let(:object) { Component.new }
          context "content is tiff image" do
            let(:file) { fixture_file_upload("imageA.tif", "image/tiff") }
            it "should generate a thumbnail and a ptif" do
              expect(object.derivatives).to receive(:generate_derivative).with(Ddr::Derivatives::DERIVATIVES[:thumbnail])
              expect(object.derivatives).to receive(:generate_derivative).with(Ddr::Derivatives::DERIVATIVES[:multires_image])
              object.derivatives.update_derivatives(:now)
            end
          end
          context "content is not tiff image" do
            let(:file) { fixture_file_upload("bird.jpg", "image/jpeg") }
            it "should generate a thumbnail and a ptif" do
              expect(object.derivatives).to receive(:generate_derivative).with(Ddr::Derivatives::DERIVATIVES[:thumbnail])
              expect(object.derivatives).to receive(:generate_derivative).with(Ddr::Derivatives::DERIVATIVES[:multires_image])
              object.derivatives.update_derivatives(:now)
            end
          end
          context "content is not tiff or jpeg image" do
            let(:file) { fixture_file_upload("arrow1rightred_e0.gif", "image/gif") }
            it "should generate a thumbnail but not a ptif" do
              expect(object.derivatives).to receive(:generate_derivative).with(Ddr::Derivatives::DERIVATIVES[:thumbnail])
              expect(object.derivatives).to_not receive(:generate_derivative).with(Ddr::Derivatives::DERIVATIVES[:multires_image])
              object.derivatives.update_derivatives(:now)
            end
          end
        end
      end
      context "not all derivatives" do
        let!(:derivs) { Ddr::Derivatives.update_derivatives }
        before { Ddr::Derivatives.update_derivatives = [ :thumbnail ] }
        after { Ddr::Derivatives.update_derivatives = derivs }
        let(:object) { Component.new }
        let(:file) { fixture_file_upload("imageA.tif", "image/tiff") }
        it "should only generate the thumbnail derivative" do
          expect(object.derivatives).to receive(:generate_derivative).with(Ddr::Derivatives::DERIVATIVES[:thumbnail])
          expect(object.derivatives).to_not receive(:generate_derivative).with(Ddr::Derivatives::DERIVATIVES[:multires_image])
          object.derivatives.update_derivatives(:now)
        end
      end
    end

    describe "derivative generation" do
      let(:file) { fixture_file_upload("imageA.tif", "image/tiff") }
      before { object.upload! file }
      describe "thumbnail" do
        let(:object) { Component.create }
        it "should create content in the thumbnail datastream" do
          expect(object.datastreams[Ddr::Datastreams::THUMBNAIL]).to_not be_present
          object.derivatives.generate_derivative! Ddr::Derivatives::DERIVATIVES[:thumbnail]
          expect(object.datastreams[Ddr::Datastreams::THUMBNAIL]).to be_present
          expect(object.datastreams[Ddr::Datastreams::THUMBNAIL].size).to be > 0
        end
      end
      describe "ptif" do
        let(:object) { Component.create }
        it "should create content in the multires image datastream" do
          expect(object.datastreams[Ddr::Datastreams::MULTIRES_IMAGE]).to_not be_present
          object.derivatives.generate_derivative! Ddr::Derivatives::DERIVATIVES[:multires_image]
          expect(object.datastreams[Ddr::Datastreams::MULTIRES_IMAGE]).to be_present
          file_uri = object.datastreams[Ddr::Datastreams::MULTIRES_IMAGE].dsLocation
          expect(File.size(Ddr::Utils.path_from_uri(file_uri))).to be > 0
        end
      end
    end

    describe "intermediate file handling" do
      let(:object) { Component.create }
      let(:file) { fixture_file_upload("imageA.tif", "image/tiff") }
      before { object.upload! file }
      describe "object has intermediate file" do
        let(:intermediate_file) { fixture_file_upload("bird.jpg", "image/jpeg") }
        before do
          object.add_file intermediate_file, Ddr::Datastreams::INTERMEDIATE_FILE
          object.save!
          object.reload
        end
        it "uses the intermediate file as the derivative source" do
          expect(object.derivatives.source_datastream).to equal(object.datastreams[Ddr::Datastreams::INTERMEDIATE_FILE])
        end
      end
      describe "object does not have intermediate file" do
        it "uses the content file as the derivative source" do
          expect(object.derivatives.source_datastream).to equal(object.datastreams[Ddr::Datastreams::CONTENT])
        end
      end
    end

    describe "exception during derivative generation" do
      let(:object) { Component.create }
      before do
        allow(Dir::Tmpname).to receive(:make_tmpname).with('', nil) { 'test-temp-dir' }
        # simulate raising of exception during derivative generation
        allow_any_instance_of(Ddr::Managers::DerivativesManager).to receive(:generate_derivative!).and_raise(StandardError)
      end
      it "should delete the temporary work directory" do
        expect(File.exist?(File.join(Dir.tmpdir, 'test-temp-dir'))).to be false
      end
    end

  end
end
