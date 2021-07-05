# frozen_string_literal: true
require "fileutils"

module Fourier
  module Utilities
    module SwiftPackageManager
      ARM64_TARGET = "arm64-apple-macosx"
      X86_64_TARGET = "x86_64-apple-macosx"

      def self.build_fat_release_library(path:, product:, output_directory:, swift_build_directory:)
        release_directory = File.expand_path("apple/Products/Release/", swift_build_directory)

        unless File.exist?(release_directory)
          FileUtils.mkdir_p(release_directory)
        end

        build = -> (arch) {
          Utilities::System.system(
            "swift", "build",
            "--configuration", "release",
            "--disable-sandbox",
            "--package-path", path,
            "--product", product,
            "--build-path", swift_build_directory,
            "--triple", "#{arch}-apple-macosx",
            "-Xswiftc", "-enable-library-evolution",
            "-Xswiftc", "-emit-module-interface",
            "-Xswiftc", "-emit-module-interface-path",
            "-Xswiftc", File.join(swift_build_directory, "#{arch}-apple-macos.swiftinterface")
          )
        }
        build.call("arm64")
        build.call("x86_64")

        system(
          "lipo", "-create",
          "-output", File.expand_path("lib#{product}.dylib", output_directory),
          File.expand_path("arm64-apple-macosx/release/lib#{product}.dylib", swift_build_directory),
          File.expand_path("x86_64-apple-macosx/release/lib#{product}.dylib", swift_build_directory)
        )
        ["arm64", "x86_64"].each do |arch|
          output_swift_module_directory = File.join(output_directory, "#{product}.swiftmodule")
          destinations = [arch, "#{arch}-apple-macos"]
          FileUtils.mkdir_p(output_swift_module_directory) unless Dir.exist?(output_swift_module_directory)

          destinations.each do |destination|
            FileUtils.cp_r(
              File.join(swift_build_directory, "#{arch}-apple-macosx/release/#{product}.swiftmodule"),
              File.join(output_swift_module_directory, "#{destination}.swiftmodule")
            )
            FileUtils.cp_r(
              File.join(swift_build_directory, "#{arch}-apple-macosx/release/#{product}.swiftdoc"),
              File.join(output_swift_module_directory, "#{destination}.swiftmodule")
            )
            FileUtils.cp_r(
              File.join(swift_build_directory, "#{arch}-apple-macos.swiftinterface"),
              File.join(output_swift_module_directory, "#{destination}.swiftinterface")
            )
          end
        end
      end

      def self.build_fat_release_binary(
        path:,
        product:,
        binary_name:,
        output_directory:,
        swift_build_directory:,
        additional_options: []
      )
        command = [
          "swift", "build",
          "--configuration", "release",
          "--disable-sandbox",
          "--package-path", path,
          "--product", product,
          "--build-path", swift_build_directory
        ]

        arm_64 = [*command, "--triple", ARM64_TARGET]
        Utilities::System.system(*arm_64)

        x86 = [*command, "--triple", X86_64_TARGET]
        Utilities::System.system(*x86)

        unless File.exist?(output_directory)
          Dir.mkdir(output_directory)
        end
        Utilities::System.system(
          "lipo", "-create", "-output", File.expand_path(binary_name, output_directory),
          File.join(swift_build_directory, "#{ARM64_TARGET}/release/#{binary_name}"),
          File.join(swift_build_directory, "#{X86_64_TARGET}/release/#{binary_name}")
        )
      end
    end
  end
end
