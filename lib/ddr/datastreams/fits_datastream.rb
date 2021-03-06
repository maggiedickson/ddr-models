module Ddr::Datastreams
  class FitsDatastream < ActiveFedora::OmDatastream

    FITS_XMLNS = "http://hul.harvard.edu/ois/xml/ns/fits/fits_output".freeze
    FITS_SCHEMA = "http://hul.harvard.edu/ois/xml/xsd/fits/fits_output.xsd".freeze

    EXIFTOOL = "Exiftool"

    set_terminology do |t|
      t.root(path: "fits",
             xmlns: FITS_XMLNS,
             schema: FITS_SCHEMA)
      t.version(path: {attribute: "version"})
      t.timestamp(path: {attribute: "timestamp"})
      t.identification {
        t.identity {
          t.mimetype(path: {attribute: "mimetype"})
          t.format_label(path: {attribute: "format"})
          t.version
          t.externalIdentifier
          t.pronom_identifier(path: "externalIdentifier", attributes: {type: "puid"})
        }
      }
      t.fileinfo {
        t.created
        t.creatingApplicationName
        t.creatingos
        t.filename
        t.filepath
        t.fslastmodified
        t.lastmodified
        t.md5checksum
        t.size
      }
      t.filestatus {
        t.valid
        t.well_formed(path: "well-formed")
      }
      t.metadata {
        t.image {
          t.imageWidth
          t.imageHeight
          t.colorSpace
          t.iccProfileName
          t.iccProfileVersion
        }
        t.document {
          # TODO - configure to get from Tika?
          # t.encoding
        }
        t.text
        t.audio
        t.video
      }

      ## proxy terms

      # identification / identity
      t.format_label         proxy: [:identification, :identity, :format_label]
      t.format_version       proxy: [:identification, :identity, :version]
      t.media_type           proxy: [:identification, :identity, :mimetype]
      t.pronom_identifier    proxy: [:identification, :identity, :pronom_identifier]

      # filestatus
      t.valid                proxy: [:filestatus, :valid]
      t.well_formed          proxy: [:filestatus, :well_formed]

      # fileinfo
      t.created              proxy: [:fileinfo, :created]
      t.creating_application proxy: [:fileinfo, :creatingApplicationName]
      t.extent               proxy: [:fileinfo, :size]
      t.md5                  proxy: [:fileinfo, :md5checksum]

      # image metadata
      t.color_space          proxy: [:metadata, :image, :colorSpace]
      t.icc_profile_name     proxy: [:metadata, :image, :iccProfileName]
      t.icc_profile_version  proxy: [:metadata, :image, :iccProfileVersion]
      t.image_height         proxy: [:metadata, :image, :imageHeight]
      t.image_width          proxy: [:metadata, :image, :imageWidth]
    end

    def self.xml_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.fits("xmlns"=>FITS_XMLNS,
                 "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                 "xsi:schemaLocation"=>"http://hul.harvard.edu/ois/xml/ns/fits/fits_output http://hul.harvard.edu/ois/xml/xsd/fits/fits_output.xsd")
      end
      builder.doc
    end

    def prefix
      "fits__"
    end

    def modified
      ng_xml
        .xpath("//fits:fileinfo/fits:lastmodified[@toolname != '#{EXIFTOOL}']", fits: FITS_XMLNS)
        .map(&:text)
    end

  end
end
