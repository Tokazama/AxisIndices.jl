
@testset "AxisIterator" begin
    axis = SimpleAxis(20)
    @test @inferred(collect(AxisIterator(axis, 3))) ==
        [1:3, 4:6, 7:9, 10:12, 13:15, 16:18]
    @test @inferred(collect(AxisIterator(axis, 3, first_pad=1))) ==
        [2:4, 5:7, 8:10, 11:13, 14:16, 17:19]
    @test @inferred(collect(AxisIterator(axis, 3, first_pad=1, last_pad=1))) ==
        [2:4, 5:7, 8:10, 11:13, 14:16, 17:19]
    @test @inferred(collect(AxisIterator(axis, 3, first_pad=1, last_pad=2))) ==
        [2:4, 5:7, 8:10, 11:13, 14:16]
    @test @inferred(collect(AxisIterator(axis, 3, first_pad=1, last_pad=2, dilation=2))) ==
        [2:2:4, 5:2:7, 8:2:10, 11:2:13, 14:2:16]
    @test @inferred(collect(AxisIterator(axis, 3, first_pad=1, last_pad=2, stride=2))) == [2:4, 7:9, 12:14]

    axis = Axis(range(2.0, step=3.0, length=20))
    itr = AxisIterator(axis, 9.0)
    @test iterate(itr) == (1:3, 0)
    @test first(itr) == 1:3
    @test iterate(itr, 0) == (4:6, 3)
    @test last(itr) == 16:18
    @test @inferred(collect(itr)) == [1:3, 4:6, 7:9, 10:12, 13:15, 16:18]

    @test @inferred(collect(AxisIterator(axis, 9.0, first_pad=3.0))) ==
        [2:4, 5:7, 8:10, 11:13, 14:16, 17:19]
    @test @inferred(collect(AxisIterator(axis, 9.0, first_pad=3.0, last_pad=3.0))) ==
        [2:4, 5:7, 8:10, 11:13, 14:16, 17:19]
    @test @inferred(collect(AxisIterator(axis, 9.0, first_pad=3.0, last_pad=6.0))) ==
        [2:4, 5:7, 8:10, 11:13, 14:16]

    itr = AxisIterator(axis, 9.0, first_pad=3.0, last_pad=6.0, dilation=6.0)
    @test iterate(itr) == (2:2:4, 1)
    @test iterate(itr, 1) == (5:2:7, 4)
    @test @inferred(collect(itr)) == [2:2:4, 5:2:7, 8:2:10, 11:2:13, 14:2:16]

    itr = AxisIterator(axis, 9.0, first_pad=3.0, last_pad=6.0, stride=6.0)
    @test iterate(itr) == (2:4, 1)
    @test iterate(itr, 1) ==(7:9, 6)
    @test @inferred(collect(itr)) == [2:4, 7:9, 12:14]
end

@testset "AxesIterator" begin
    axis = SimpleAxis(20)
    A = CartesianIndices((axis, axis, axis));
    axsitr = AxesIterator(A, (3,3,3), first_pad=(1,1,1), last_pad=(2,2,2), stride=(2,2,2))

    @test AxisIndices.Interface.firstinc(axsitr.iterators) == ((2:4, 2:4, 2:4), (1, 1, 1))
    @test iterate(axsitr) == ((2:4, 2:4, 2:4), ((2:4, 2:4, 2:4), (1, 1, 1)))
    @test first(axsitr) == (2:4, 2:4, 2:4)
    @test last(axsitr) == (12:14, 12:14, 12:14)

    @test collect(axsitr) == [(2:4, 2:4, 2:4),
                    (7:9, 2:4, 2:4),
                    (12:14, 2:4, 2:4),
                    (2:4, 7:9, 2:4),
                    (7:9, 7:9, 2:4),
                    (12:14, 7:9, 2:4),
                    (2:4, 12:14, 2:4),
                    (7:9, 12:14, 2:4),
                    (12:14, 12:14, 2:4),
                    (2:4, 2:4, 7:9),
                    (7:9, 2:4, 7:9),
                    (12:14, 2:4, 7:9),
                    (2:4, 7:9, 7:9),
                    (7:9, 7:9, 7:9),
                    (12:14, 7:9, 7:9),
                    (2:4, 12:14, 7:9),
                    (7:9, 12:14, 7:9),
                    (12:14, 12:14, 7:9),
     (2:4, 2:4, 12:14),
     (7:9, 2:4, 12:14),
     (12:14, 2:4, 12:14),
     (2:4, 7:9, 12:14),
     (7:9, 7:9, 12:14),
     (12:14, 7:9, 12:14),
     (2:4, 12:14, 12:14),
     (7:9, 12:14, 12:14),
     (12:14, 12:14, 12:14)]
end
