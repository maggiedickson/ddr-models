module Ddr::Index
  RSpec.describe CSVQueryResult do

    subject { described_class.new(query) }

    before do
      Item.create(title: ["Testing 1"],
                  identifier: ["test1"],
                  description: ["The process of\r\neliminating errors\nmust include checking newlines."])
      Item.create(title: ["Testing 2"],
                  identifier: ["test2"])
      Item.create(title: ["Testing 3"])
    end

    let(:query) {
      Ddr::Index::Query.new do
        fields Ddr::Index::Fields::ID
        fields Ddr::Index::Fields.descmd
      end
    }

    specify {
      expect(subject["title"]).to contain_exactly("Testing 1", "Testing 2", "Testing 3")
      expect(subject["identifier"]).to contain_exactly("test1", "test2", nil)
      expect(subject["description"]).to contain_exactly("The process of\r\neliminating errors\nmust include checking newlines.", nil, nil)
      expect(subject["creator"]).to contain_exactly(nil, nil, nil)
      expect(subject.headers).to include("creator")
      expect(subject.to_s).to match(/creator/)
    }

    describe "#delete_empty_columns!" do
      specify {
        subject.delete_empty_columns!
        expect(subject["title"]).to contain_exactly("Testing 1", "Testing 2", "Testing 3")
        expect(subject["identifier"]).to contain_exactly("test1", "test2", nil)
        expect(subject["description"]).to contain_exactly("The process of\r\neliminating errors\nmust include checking newlines.", nil, nil)
        expect(subject["creator"]).to contain_exactly(nil, nil, nil)
        expect(subject.headers).to contain_exactly("pid", "title", "identifier", "description")
        expect(subject.to_s).not_to match(/creator/)
      }
    end

  end
end
