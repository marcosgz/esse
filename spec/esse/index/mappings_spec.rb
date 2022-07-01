# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Esse::Index do
  describe '.mappings_hash' do
    context 'with definition only on index level' do
      before do
        stub_index(:geos) do
          mappings do
            {
              'properties' => {
                'age' => { 'type' => 'integer' },
              },
            }
          end

          repository :city
          repository :county
        end
      end

      it 'merges the global mapping into each type definition on elasticsearch 5.x and lower' do
        allow(GeosIndex.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '5.0.0', distribution: 'elasticsearch'))
        expect(GeosIndex.mappings_hash).to eq(
          'mappings' => {
            'city' => {
              'properties' => {
                'age' => { 'type' => 'integer' },
              },
            },
            'county' => {
              'properties' => {
                'age' => { 'type' => 'integer' },
              },
            },
          },
        )
      end

      it "adds the _doc type to the index's mappings on elasticsearch 6.4 and upper" do
        allow(GeosIndex.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '6.4.0', distribution: 'elasticsearch'))
        expect(GeosIndex.mappings_hash).to eq(
          'mappings' => {
            '_doc' => {
              'properties' => {
                'age' => { 'type' => 'integer' },
              },
            },
          },
        )
      end

      it "adds the doc type to the index's mappings on elasticsearch 6.3 and lower" do
        allow(GeosIndex.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '6.3.0', distribution: 'elasticsearch'))
        expect(GeosIndex.mappings_hash).to eq(
          'mappings' => {
            'doc' => {
              'properties' => {
                'age' => { 'type' => 'integer' },
              },
            },
          },
        )
      end

      it "does not include the type on index's mappings on elasticsearch 7.x" do
        allow(GeosIndex.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '7.0.0', distribution: 'elasticsearch'))
        expect(GeosIndex.mappings_hash).to eq(
          'mappings' => {
            'properties' => {
              'age' => { 'type' => 'integer' },
            },
          },
        )
      end

      it "does not include the type on index's mappings on opensearch" do
        allow(GeosIndex.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '1.0.0', distribution: 'opensearch'))
        expect(GeosIndex.mappings_hash).to eq(
          'mappings' => {
            'properties' => {
              'age' => { 'type' => 'integer' },
            },
          },
        )
      end
    end

    context 'with definition only both index and type level' do
      before do
        stub_index(:geos) do
          mappings do
            {
              'properties' => {
                'age' => { 'type' => 'integer' },
              },
            }
          end

          repository :city do
            mappings do
              {
                'properties' => {
                  'name' => { 'type' => 'string' },
                },
              }
            end
          end
          repository :county
        end
      end

      it 'merges the global mapping into each type definition on elasticsearch 5.x and lower' do
        allow(GeosIndex.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '5.0.0', distribution: 'elasticsearch'))
        expect(GeosIndex.mappings_hash).to eq(
          'mappings' => {
            'city' => {
              'properties' => {
                'age' => { 'type' => 'integer' },
                'name' => { 'type' => 'string' },
              },
            },
            'county' => {
              'properties' => {
                'age' => { 'type' => 'integer' },
              },
            },
          },
        )
      end

      it "adds the _doc type to the index's mappings on elasticsearch 6.4 and upper" do
        allow(GeosIndex.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '6.4.0', distribution: 'elasticsearch'))
        expect(GeosIndex.mappings_hash).to eq(
          'mappings' => {
            '_doc' => {
              'properties' => {
                'age' => { 'type' => 'integer' },
                'name' => { 'type' => 'string' },
              },
            },
          },
        )
      end

      it "adds the doc type to the index's mappings on elasticsearch 6.3 and lower" do
        allow(GeosIndex.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '6.3.0', distribution: 'elasticsearch'))
        expect(GeosIndex.mappings_hash).to eq(
          'mappings' => {
            'doc' => {
              'properties' => {
                'age' => { 'type' => 'integer' },
                'name' => { 'type' => 'string' },
              },
            },
          },
        )
      end

      it "does not include the type on index's mappings on elasticsearch 7.x" do
        allow(GeosIndex.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '7.0.0', distribution: 'elasticsearch'))
        expect(GeosIndex.mappings_hash).to eq(
          'mappings' => {
            'properties' => {
              'age' => { 'type' => 'integer' },
              'name' => { 'type' => 'string' },
            },
          },
        )
      end

      it "does not include the type on index's mappings on opensearch" do
        allow(GeosIndex.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '1.0.0', distribution: 'opensearch'))
        expect(GeosIndex.mappings_hash).to eq(
          'mappings' => {
            'properties' => {
              'age' => { 'type' => 'integer' },
              'name' => { 'type' => 'string' },
            },
          },
        )
      end
    end

    context 'with definition only on type level' do
      before do
        stub_index(:geos) do
          repository :city do
            mappings do
              {
                'properties' => {
                  'name' => { 'type' => 'string' },
                },
              }
            end
          end
          repository :county do
            mappings do
              {
                'age' => { 'type' => 'integer' },
              }
            end
          end
        end
      end

      it 'merges the global mapping into each type definition on elasticsearch 5.x and lower' do
        allow(GeosIndex.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '5.0.0', distribution: 'elasticsearch'))
        expect(GeosIndex.mappings_hash).to eq(
          'mappings' => {
            'city' => {
              'properties' => {
                'name' => { 'type' => 'string' },
              },
            },
            'county' => {
              'properties' => {
                'age' => { 'type' => 'integer' },
              },
            },
          },
        )
      end

      it "adds the _doc type to the index's mappings on elasticsearch 6.4 and upper" do
        allow(GeosIndex.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '6.4.0', distribution: 'elasticsearch'))
        expect(GeosIndex.mappings_hash).to eq(
          'mappings' => {
            '_doc' => {
              'properties' => {
                'age' => { 'type' => 'integer' },
                'name' => { 'type' => 'string' },
              },
            },
          },
        )
      end

      it "adds the doc type to the index's mappings on elasticsearch 6.3 and lower" do
        allow(GeosIndex.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '6.3.0', distribution: 'elasticsearch'))
        expect(GeosIndex.mappings_hash).to eq(
          'mappings' => {
            'doc' => {
              'properties' => {
                'age' => { 'type' => 'integer' },
                'name' => { 'type' => 'string' },
              },
            },
          },
        )
      end

      it "does not include the type on index's mappings on elasticsearch 7.x" do
        allow(GeosIndex.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '7.0.0', distribution: 'elasticsearch'))
        expect(GeosIndex.mappings_hash).to eq(
          'mappings' => {
            'properties' => {
              'age' => { 'type' => 'integer' },
              'name' => { 'type' => 'string' },
            },
          },
        )
      end

      it "does not include the type on index's mappings on opensearch" do
        allow(GeosIndex.cluster).to receive(:engine).and_return(Esse::ClusterEngine.new(version: '1.0.0', distribution: 'opensearch'))
        expect(GeosIndex.mappings_hash).to eq(
          'mappings' => {
            'properties' => {
              'age' => { 'type' => 'integer' },
              'name' => { 'type' => 'string' },
            },
          },
        )
      end
    end
  end
end
