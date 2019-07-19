# frozen_string_literal: true

require 'spec_helper'

describe Fedex::Request::UploadImages do
  let(:fedex) { Fedex::Shipment.new(fedex_development_credentials) }

  subject { fedex.upload_images(options) }

  def build_image_fixture(path)
    File.new(File.join(File.dirname(__dir__), '../fixtures/', path))
  end

  context 'when options include images key', :vcr do
    context 'when both images in params are a valid image', :vcr do
      let(:options) do
        {
          images: [
            { id: 'IMAGE_1', image: build_image_fixture('requests/upload_images/letterhead_image_regular.png') },
            { id: 'IMAGE_2', image: build_image_fixture('requests/upload_images/signature_image_regular.png') }
          ]
        }
      end

      it 'returns an array of images uploaded with the status' do
        expect(subject).to include(
          image_statuses: [
            { id: 'IMAGE_1', status: 'SUCCESS' },
            { id: 'IMAGE_2', status: 'SUCCESS' }
          ]
        )
      end
    end

    context 'when one of two images in params are invalid', :vcr do
      let(:options) do
        {
          images: [
            { id: 'IMAGE_1', image: build_image_fixture('requests/upload_images/letterhead_image_regular.png') },
            { id: 'IMAGE_2', image: build_image_fixture('requests/upload_images/signature_image_size_too_large.png') }
          ]
        }
      end

      it 'returns an array of images uploaded and errors with the status' do
        expect(subject).to include(
          image_statuses: [
            {
              id: 'IMAGE_2',
              status: 'ERROR',
              status_info: 'IMAGE_EXCEEDS_MAX_RESOLUTION',
              message: 'Your selected image exceeds the max resolution of 700 pixels wide by 50 pixels long.'
            },
            {
              id: 'IMAGE_1',
              status: 'SUCCESS'
            }
          ]
        )
      end
    end

    context 'when image in params are not a type of a file' do
      let(:options) do
        {
          images: [
            { id: 'IMAGE_1', image: 'NotaValidFile' }
          ]
        }
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Fedex::RateError, 'Image must be a type of file')
      end
    end
  end

  context 'when options does not include images key' do
    let(:options) do
      {}
    end

    it 'raises an error' do
      expect { subject }.to raise_error(Fedex::RateError, 'Missing Required Parameter images')
    end
  end
end
