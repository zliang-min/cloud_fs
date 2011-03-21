# -*- encoding: utf-8 -*-

require 'digest/md5'
require 'RMagick'

module CloudFS
  module Utils
    class << self
      # @yield [Magick::Image]
      def resize_image(image, size, &blk)
        img = magick_image image

        size = size.to_s
        scale =
          if size['x']
            width, height = size.split 'x'
            # 支持x123和123x这种只限制宽/高的参数。
            width  ||= img.columns
            height ||= img.rows
            [width.to_f / img.columns, height.to_f / img.rows].min
          else
            size.to_f / [img.columns, img.rows].min
          end

        if scale < 1
          img.scale! (img.columns * scale).to_i, (img.rows * scale).to_i
          blk.call img
        end
      ensure
        img.destroy! if img && !img.destroyed?
      end

      # @yield [Magick::Image]
      def watermark(image, watermark)
        bg = magick_image image
        fg = magick_image watermark

        # It's too difficult for me to adjust the values to get a good result. T_T
        # Give up using watermark method which is using ModulateCompositeOp.
        #img = bg.watermark(fg, 0.5, 0.5, Magick::SouthWestGravity)
        img = bg.composite(fg, Magick::SouthWestGravity, Magick::OverCompositeOp)

        bg.destroy!
        fg.destroy!

        yield img if block_given?
      ensure
        bg.destroy!  if bg  && !bg.destroyed?
        fg.destroy!  if fg  && !fg.destroyed?
        img.destroy! if img && !img.destroyed?
      end

      def magick_image(file)
        if file.is_a?(Magick::Image) then file
        else
          image = Magick::Image.from_blob(file.respond_to?(:read) ? file.read : file).first
          file.respond_to?(:rewind) and file.rewind
          image
        end
      end

      def md5(object)
        object.respond_to?(:rewind) and object.rewind
        md5 = Digest::MD5.hexdigest object.respond_to?(:read) ? object.read : object.to_s
        object.respond_to?(:rewind) and object.rewind
        md5
      end
    end
  end
end
