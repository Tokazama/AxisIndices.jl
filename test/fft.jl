
@testset "fft-tests" begin
    x = reshape(1:6, 2, 3)
    ax = AxisArray(x, 2:3, 3.0:5.0)

    @testset "fft" begin
        x_fft = fft(x, 2)
        ax_fft = fft(ax, 2)
        @test x_fft == ax_fft
        @test keys.(axes(ax_fft)) == keys.(axes(ax))
    end

    @testset "ifft" begin
        x_ifft = ifft(x, 2)
        ax_ifft = ifft(ax, 2)
        @test ax_ifft == x_ifft
        @test keys.(axes(ax_ifft)) == keys.(axes(ax))
    end

    @testset "bfft" begin
        x_bfft = bfft(x, 2)
        ax_bfft = bfft(ax, 2)
        @test ax_bfft == x_bfft
        @test keys.(axes(ax_bfft)) == keys.(axes(ax))
    end
end

