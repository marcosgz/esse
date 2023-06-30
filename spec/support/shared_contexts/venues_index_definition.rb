# frozen_string_literal: true

RSpec.shared_context 'with venues index definition' do
  let(:restaurant) do
    { id: 1, name: 'Gourmet Paradise' }
  end
  let(:hotel) do
    { id: 2, name: 'Hotel California' }
  end
  let(:auditorium) do
    { id: 3, name: 'Parco della Musica' }
  end
  let(:venues) do
    [restaurant, hotel, auditorium]
  end
  let(:total_venues) { venues.size }

  before do
    # closure for the stub_index block
    ds = venues

    stub_index(:venues) do
      repository :default do
        collection do |**context, &block|
          block.call(ds, **context) unless ds.empty?
        end
        serializer do |venue, **context|
          {
            _id: venue[:id],
            name: venue[:name],
          }
        end
      end
    end
  end
end
