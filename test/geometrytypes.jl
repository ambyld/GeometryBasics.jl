using Test, GeometryBasics

@testset "algorithms.jl" begin
    cube = Rect(Vec3f0(-0.5), Vec3f0(1))
    cube_faces = decompose(TriangleFace{Int}, faces(cube))
    cube_vertices = decompose(Point{3,Float32}, cube)
    @test area(cube_vertices, cube_faces) == 6
    mesh = Mesh(cube_vertices, cube_faces)
    @test GeometryBasics.volume(mesh) ≈ 1
end

@testset "Cylinder" begin
    @testset "constructors" begin
        o, extr, r = Point2f0(1, 2), Point2f0(3, 4), 5f0
        s = Cylinder(o, extr, r)
        @test typeof(s) == Cylinder{2,Float32}
        @test typeof(s) == Cylinder2{Float32}
        @test origin(s) == o
        @test extremity(s) == extr
        @test radius(s) == r
        #@test abs(height(s)- norm([1,2]-[3,4]))<1e-5
        h = norm(o - extr)
        @test isapprox(height(s), h)
        #@test norm(direction(s) - Point{2,Float32}([2,2]./norm([1,2]-[3,4])))<1e-5
        @test isapprox(direction(s), Point2f0(2, 2) ./ h)
        v1 = rand(Point{3, Float64}); v2 = rand(Point{3, Float64}); R = rand()
        s = Cylinder(v1, v2, R)
        @test typeof(s) == Cylinder{3, Float64}
        @test typeof(s) == Cylinder3{Float64}
        @test origin(s) == v1
        @test extremity(s) == v2
        @test radius(s) == R
        @test height(s) == norm(v2 - v1)
        #@test norm(direction(s) - Point{3,Float64}((v2-v1)./norm(v2-v1)))<1e-10
        @test isapprox(direction(s), (v2-v1) ./ norm(v2 .- v1))
    end

    @testset "decompose" begin

        o, extr, r = Point2f0(1, 2), Point2f0(3, 4), 5f0
        s = Cylinder(o, extr, r)
        positions = Point{3, Float32}[
            (-0.7677671, 3.767767, 0.0),
            (2.767767, 0.23223293, 0.0),
            (0.23223293, 4.767767, 0.0),
            (3.767767, 1.2322329, 0.0),
            (1.2322329, 5.767767, 0.0),
            (4.767767, 2.232233, 0.0)
        ]
        @test decompose(Point3f0, Tesselation(s, (2, 3))) ≈ positions

        FT = TriangleFace{Int}
        faces = FT[
            (1,2,4),
            (1,4,3),
            (3,4,6),
            (3,6,5)
        ]
        @test faces == decompose(FT, Tesselation(s, (2,3)))

        v1 = Point{3, Float64}(1,2,3); v2 = Point{3, Float64}(4,5,6); R = 5.0
        s = Cylinder(v1, v2, R)
        positions = Point{3,Float64}[
            (4.535533905932738,-1.5355339059327373,3.0),
            (7.535533905932738,1.4644660940672627,6.0),
            (3.0412414523193148,4.041241452319315,-1.0824829046386295),
            (6.041241452319315,7.041241452319315,1.9175170953613705),
            (-2.535533905932737,5.535533905932738,2.9999999999999996),
            (0.46446609406726314,8.535533905932738,6.0),
            (-1.0412414523193152,-0.04124145231931431,7.0824829046386295),
            (1.9587585476806848,2.9587585476806857,10.08248290463863),
            (1,2,3),
            (4,5,6)
        ]

        @test decompose(Point3{Float64}, Tesselation(s, 8)) ≈ positions

        faces = TriangleFace{Int}[
            (3, 2, 1),
            (4, 2, 3),
            (5, 4, 3),
            (6, 4, 5),
            (7, 6, 5),
            (8, 6, 7),
            (1, 8, 7),
            (2, 8, 1),

            (3, 1, 9),
            (2, 4, 10),
            (5, 3, 9),
            (4, 6, 10),
            (7, 5, 9),
            (6, 8, 10),
            (1, 7, 9),
            (8, 2, 10)
        ]
        @test faces == decompose(TriangleFace{Int}, Tesselation(s, 8))

        m = triangle_mesh(Tesselation(s, 8))

        @test GeometryBasics.faces(m) == faces
        @test GeometryBasics.coordinates(m) ≈ positions
        m = normal_mesh(s)# just test that it works without explicit resolution parameter
        @test m isa GLNormalMesh

        muv = uv_mesh(s)
        @test Rect(Point.(texturecoordinates(muv))) == FRect2D(Vec2f0(0), Vec2f0(1.0))
    end
end


@testset "HyperRectangles" begin
    a = Rect(Vec(0,0),Vec(1,1))
    pt_expa = Point{2,Int}[(0,0), (1,0), (0,1), (1,1)]
    @test decompose(Point{2,Int},a) == pt_expa
    mesh = normal_mesh(a)
    @test decompose(Point2f0, mesh) == pt_expa

    b = Rect(Vec(1,1,1),Vec(1,1,1))
    pt_expb = Point{3,Int64}[[1, 1, 1], [1, 1, 2], [1, 2, 2], [1, 2, 1], [1, 1, 1], [2, 1, 1], [2, 1, 2], [1, 1, 2], [1, 1, 1], [1, 2, 1], [2, 2, 1], [2, 1, 1], [2, 2, 2], [1, 2, 2], [1, 1, 2], [2, 1, 2], [2, 2, 2], [2, 1, 2], [2, 1, 1], [2, 2, 1], [2, 2, 2], [2, 2, 1], [1, 2, 1], [1, 2, 2]]
    @test decompose(Point{3,Int}, b) == pt_expb
    mesh = normal_mesh(b)
end


NFace = NgonFace

@testset "Faces" begin
    @test convert_simplex(GLTriangleFace, QuadFace{Int}(1,2,3,4)) == (GLTriangleFace(1,2,3), GLTriangleFace(1,3,4))
    @test convert_simplex(NFace{3, ZeroIndex{Int}}, QuadFace{ZeroIndex{Int}}(1,2,3,4)) == (NFace{3,ZeroIndex{Int}}(1,2,3), NFace{3, ZeroIndex{Int}}(1,3,4))
    @test convert_simplex(NFace{3, OffsetInteger{3, Int}}, NFace{4, OffsetInteger{2, Int}}(1,2,3,4)) == (
            NFace{3, OffsetInteger{3, Int}}(1,2,3),
            NFace{3, OffsetInteger{3, Int}}(1,3,4)
    )
    @test convert_simplex(LineFace{Int}, QuadFace{Int}(1,2,3,4)) == (
        LineFace{Int}(1,2),
        LineFace{Int}(2,3),
        LineFace{Int}(3,4),
        LineFace{Int}(4,1)
    )
end



@testset "Normals" begin
    n64 = Vec{3, Float64}[
        (0.0,0.0,-1.0),
        (0.0,0.0,-1.0),
        (0.0,0.0,-1.0),
        (0.0,0.0,-1.0),
        (0.0,0.0,1.0),
        (0.0,0.0,1.0),
        (0.0,0.0,1.0),
        (0.0,0.0,1.0),
        (-1.0,0.0,0.0),
        (-1.0,0.0,0.0),
        (-1.0,0.0,0.0),
        (-1.0,0.0,0.0),
        (1.0,0.0,0.0),
        (1.0,0.0,0.0),
        (1.0,0.0,0.0),
        (1.0,0.0,0.0),
        (0.0,1.0,0.0),
        (0.0,1.0,0.0),
        (0.0,1.0,0.0),
        (0.0,1.0,0.0),
        (0.0,-1.0,0.0),
        (0.0,-1.0,0.0),
        (0.0,-1.0,0.0),
        (0.0,-1.0,0.0),
    ]
    n32 = map(Vec{3,Float32}, n64)
    r = triangle_mesh(centered(Rect3D))
    # @test normals(coordinates(r), GeometryBasics.faces(r)) == n32
    # @test normals(coordinates(r), GeometryBasics.faces(r)) == n64
end


@testset "HyperSphere" begin
    sphere = Sphere{Float32}(Point3f0(0), 1f0)

    points = decompose(Point, Tesselation(sphere, 3))
    point_target = Point{3,Float32}[
        [0.0, 0.0, 1.0], [1.0, 0.0, 6.12323e-17], [1.22465e-16, 0.0, -1.0],
        [-0.0, 0.0, 1.0], [-1.0, 1.22465e-16, 6.12323e-17],
        [-1.22465e-16, 1.49976e-32, -1.0], [0.0, -0.0, 1.0],
        [1.0, -2.44929e-16, 6.12323e-17], [1.22465e-16,-2.99952e-32, -1.0]
    ]
    @test points ≈ point_target

    f = decompose(TriangleFace{Int}, Tesselation(sphere, 3))
    face_target = TriangleFace{Int}[
        [1, 2, 5], [1, 5, 4], [2, 3, 6], [2, 6, 5],
        [4, 5, 8], [4, 8, 7], [5, 6, 9], [5, 9, 8]
    ]
    @test f == face_target
    circle = Circle(Point2f0(0), 1f0)
    points = decompose(Point2f0, Tesselation(circle, 20))
    @test length(points) == 20
    tess_circle = Tesselation(circle, 32)
    mesh = triangle_mesh(tess_circle)
    @test decompose(Point2f0, mesh) ≈ decompose(Point2f0, tess_circle)
end

@testset "Rectangles" begin
    rect = FRect2D(0, 7, 20, 3)
    @test (rect + 4) == FRect2D(4, 11, 20, 3)
    @test (rect + Vec(2, -2)) == FRect2D(2, 5, 20, 3)

    @test (rect - 4) == FRect2D(-4, 3, 20, 3)
    @test (rect - Vec(2, -2)) == FRect2D(-2, 9, 20, 3)

    base = Vec3f0(1, 2, 3)
    wxyz = Vec3f0(-2, 4, 2)
    rect = FRect3D(base, wxyz)
    @test (rect + 4) == FRect3D(base .+ 4, wxyz)
    @test (rect + Vec(2, -2, 3)) == FRect3D(base .+ Vec(2, -2, 3), wxyz)

    @test (rect - 4) == FRect3D(base .- 4, wxyz)
    @test (rect - Vec(2, -2, 7)) == FRect3D(base .- Vec(2, -2, 7), wxyz)


    rect = FRect2D(0, 7, 20, 3)
    @test (rect * 4) == FRect2D(0, 7*4, 20*4, 3*4)
    @test (rect * Vec(2, -2)) == FRect2D(0, -7*2, 20*2, -3*2)

    base = Vec3f0(1, 2, 3)
    wxyz = Vec3f0(-2, 4, 2)
    rect = FRect3D(base, wxyz)
    @test (rect * 4) == FRect3D(base .* 4, wxyz .* 4)
    @test (rect * Vec(2, -2, 3)) == FRect3D(base .* Vec(2, -2, 3), wxyz .* Vec(2, -2, 3))

    rect1 = Rect(Vec(0.0, 0.0), Vec(1.0, 2.0))
    rect2 = Rect(0.0, 0.0, 1.0, 2.0)
    @test rect1 isa GeometryBasics.HyperRectangle{2, Float64}
    @test rect1 == rect2

    split1, split2 = GeometryBasics.split(rect1, 2, 1)
    @test widths(split1) == widths(split2)
    @test origin(split1) == Vec(0, 0)
    @test origin(split2) == Vec(0, 1)
    @test in(split1, rect1)
    @test !in(rect1, split1)

    prim = Rect(0.0, 0.0, 1.0, 1.0)
    @test length(prim) == 2

    @test width(prim) == 1.0
    @test height(prim) == 1.0

    b1 = Rect2D(0.0, 0.0, 2.0, 2.0)
    b2 = Rect2D(0, 0, 2, 2)
    @test isequal(b1, b2)

    pt = Point(1.0, 1.0)
    b1 = Rect(0.0, 0.0, 1.0, 1.0)
    @test in(pt, b1)

    rect = Rect(0.0, 0.0, 1.0, 1.0)
    @test GeometryBasics.positive_widths(rect) isa GeometryBasics.HyperRectangle{2,Float64}

    h1 = Rect(0.0, 0.0, 1.0, 1.0)
    h2 = Rect(1.0, 1.0, 2.0, 2.0)
    @test union(h1, h2) isa GeometryBasics.HyperRectangle{2,Float64}
    @test GeometryBasics.diff(h1, h2) == h1
    @test GeometryBasics.intersect(h1, h2) isa GeometryBasics.HyperRectangle{2,Float64}

    b = Rect(0.0, 0.0, 1.0, 1.0)
    v = Vec(1, 2)
    @test update(b, v) isa GeometryBasics.HyperRectangle{2,Float64}
    v = Vec(1.0, 2.0)
    @test update(b, v) isa GeometryBasics.HyperRectangle{2,Float64}

    p = Vec(5.0, 4.0)
    rect = Rect(0.0, 0.0, 1.0, 1.0)
    @test min_dist_dim(rect, p, 1) == 4.0
    @test min_dist_dim(rect, p, 2) == 3.0
    @test max_dist_dim(rect, p ,1) == 5.0
    @test max_dist_dim(rect, p ,2) == 4.0

    rect1 = Rect(0.0, 0.0, 1.0, 1.0)
    rect2 = Rect(3.0, 1.0, 4.0, 2.0)
    @test min_dist_dim(rect1, rect2, 1) == 2.0
    @test min_dist_dim(rect1, rect2, 2) == 0.0
    @test max_dist_dim(rect1, rect2, 1) == 7.0
    @test max_dist_dim(rect1, rect2, 2) == 3.0

    @test !before(rect1, rect2)
    rect1 = Rect(0.0, 0.0, 1.0, 1.0)
    rect2 = Rect(3.0, 2.0, 4.0, 2.0)
    @test before(rect1, rect2)

    @test !meets(rect1, rect2)
    rect2 = Rect(1.0, 1.0, 4.0, 2.0)
    @test meets(rect1, rect2)

    rect1 = Rect(1.0, 1.0, 2.0, 2.0)
    rect2 = Rect(0.0, 0.0, 2.0, 1.0)
    @test !overlaps(rect1, rect2)
    rect1 = Rect(1.0, 1.0, 2.0, 2.0)
    rect2 = Rect(1.5, 1.5, 2.0, 2.0)
    @test overlaps(rect1, rect2)


    rect1 = Rect(1.0, 1.0, 2.0, 2.0)
    rect2 = Rect(0.0, 0.0, 2.0, 1.0)
    @test !GeometryBasics.starts(rect1, rect2)
    rect2 = Rect(1.0, 1.0, 1.5, 1.5)
    @test !GeometryBasics.starts(rect1, rect2)
    rect2 = Rect(1.0, 1.0, 3.0, 3.0)
    @test GeometryBasics.starts(rect1, rect2)

    rect1 = Rect(1.0, 1.0, 2.0, 2.0)
    rect2 = Rect(0.0, 0.0, 4.0, 4.0)
    @test during(rect1, rect2)
    rect1 = Rect(0.0, 0.0, 2.0, 3.0)
    rect2 = Rect(1.0, 1.0, 4.0, 2.0)
    @test !during(rect1, rect2)

    rect1 = Rect(1.0, 1.0, 2.0, 2.0)
    rect2 = Rect(0.0, 0.0, 4.0, 4.0)
    @test !finishes(rect1, rect2)
    rect1 = Rect(1.0, 0.0, 1.0, 1.0)
    rect2 = Rect(0.0, 0.0, 2.0, 1.0)
    @test !finishes(rect1, rect2)
    rect1 = Rect(1.0, 1.0, 1.0, 2.0)
    rect2 = Rect(0.0, 0.0, 2.0, 3.0)
    @test finishes(rect1, rect2)

end
