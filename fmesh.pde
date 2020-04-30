class fieldMesh {
    MESH AM;
    int[] CT;  //encodes the color of the opposite edge
    // -1: yellow edge
    // 0: metal edge
    // 1: magenta edge
    int[] validity;
    int skinnyThreshold = 8;
    int corner = 0;

    void initiate() {
        AM = new MESH();
        CT = new int[3 * M.maxnt];
        AM.reset();
        AM.loadVertices(R.G, R.nv);
        AM.loadVectors(R.V, R.nv);
        AM.triangulate();
        for (int i = 0; i < subdivided; i++) {
            SUBDIVIDER.subdivide(AM);
        }
        for (int i = 0; i < AM.nc; i++) {
            CT[i] = -1;
        }
        AM.computeO();
    }

    int CountNarrowTriangles() {
        int skinny = 0;
        for (int i = 0; i < AM.nt; i++) {
            int a = 3*i, b = AM.n(3*i), c = AM.p(3*i);
            if (validity[a] == 1 && validity[b] == 1 && validity[c] == 1) {
                // this is an uncollapsed triangle, check if it is skinny
                float e1l = d(AM.g(a), AM.g(b));
                float e2l = d(AM.g(b), AM.g(c));
                float e3l = d(AM.g(c), AM.g(a));

                float cR = e1l*e2l*e3l/sqrt((e1l+e2l+e3l)*(-1*e1l+e2l+e3l)*(e1l-e2l+e3l)*(e1l+e2l-e3l));
                float iR = e1l*e2l*e3l/(2*cR*(e1l+e2l+e3l));

                if (cR/iR > skinnyThreshold) {
                    skinny += 1;
                    fill(orange);
                    show(P(AM.g(a).x, AM.g(a).y, AM.g(a).z+8.5), 
                         P(AM.g(b).x, AM.g(b).y, AM.g(b).z+8.5),
                         P(AM.g(c).x, AM.g(c).y, AM.g(c).z+8.5)
                    );
                }
            } 
        }
        println("Skinny Triangles:", skinny);
        return skinny;
    }

    boolean ChooseEdge (pt p1, pt p2, pt p3, pt p4) {
        if (mode == 0) {
            // Longer Edge
            return d(p1, p3) > d(p2, p4);
        } else if (mode == 1) {
            // Shorter Edge
            return d(p1, p3) < d(p2, p4);
        } else if (mode == 2) {
            // Edge aligned to the Trace
            return abs(dot(U(p1, p2), U(p1, p3))) > abs(dot(U(p1, p2), U(p2, p4)));
        } else if (mode == 3) {
            // Delaunay Criterion
            pt c1 = CircumCenter(p1, p2, p3);
            pt c2 = CircumCenter(p3, p4, p1);
            if (d(c1, p4) > d(c1, p1) && d(c2, p2) > d(c2, p1)) {
                return true;
            }
            return false;
        }
        return true;
    }

    boolean ComputeFATM (int c1, int c2, int c3) {
        boolean fatEdgeDone = false;
        for (int i = 0; i < TRACER.stabs.get(c1).size(); i++) {
            for (int j = 0; j < TRACER.stabs.get(c2).size(); j++) {
                tracePt p1 = TRACER.stabs.get(c1).get(i);
                tracePt p2 = TRACER.stabs.get(c2).get(j);
                if (p1.traceId == p2.traceId) {
                    // fill(magenta);
                    // beam(p1.point, p2.point, rt);
                    // create new vertices in the mesh
                    AM.G[p1.vid] = P(p1.point); // println(p1.vid);
                    AM.G[p2.vid] = P(p2.point); // println(p2.vid); println(AM.nv);
                    AM.nv += 2;
                    fatEdgeDone = true;
                    // Draw the Non Fat Edges
                    if (TRACER.stabs.get(c3).size() == 1) {
                        // Connect with the opposite tracepoint
                        tracePt p3 = TRACER.stabs.get(c3).get(0);
                        // fill(metal);
                        // beam(p1.point, p3.point, rt);
                        // beam(p2.point, p3.point, rt);
                        // update corner table
                        AM.V[3*AM.nt] = p1.vid; 
                        CT[3*AM.nt] = -1;
                        AM.V[AM.n(3*AM.nt)] = AM.V[c2]; 
                        CT[AM.n(3*AM.nt)] = 1;
                        AM.V[AM.p(3*AM.nt)] = p2.vid; 
                        CT[AM.p(3*AM.nt)] = -1;

                        AM.V[3+3*AM.nt] = p3.vid; 
                        CT[3+3*AM.nt] = 1;
                        AM.V[AM.n(3+3*AM.nt)] = p1.vid; 
                        CT[AM.n(3+3*AM.nt)] = 0;
                        AM.V[AM.p(3+3*AM.nt)] = p2.vid; 
                        CT[AM.p(3+3*AM.nt)] = 0;
                        
                        AM.V[6+3*AM.nt] = p3.vid; 
                        CT[6+3*AM.nt] = -1;
                        AM.V[AM.n(6+3*AM.nt)] = p2.vid; 
                        CT[AM.n(6+3*AM.nt)] = -1;
                        AM.V[AM.p(6+3*AM.nt)] = AM.V[c3]; 
                        CT[AM.p(6+3*AM.nt)] = 0;

                        AM.V[c2] = p1.vid; 
                        CT[c2] = -1;
                        AM.V[c3] = p3.vid; 
                        CT[c3] = -1;
                        CT[c1] = 0;
                        // update counts
                        AM.nt += 3;
                        AM.nc += 9;
                    } else {
                        // println("here");
                        // Connect with one of the vertices, c1 or c3
                        AM.V[3+3*AM.nt] = p1.vid;
                        CT[3+3*AM.nt] = -1;
                        AM.V[AM.n(3+3*AM.nt)] = AM.V[c2];
                        CT[AM.n(3+3*AM.nt)] = 1;
                        AM.V[AM.p(3+3*AM.nt)] = p2.vid;
                        CT[AM.p(3+3*AM.nt)] = -1;
                        
                        pt p31 = M.g(c1), p32 = M.g(c3);
                        if (ChooseEdge(p1.point, p2.point, p32, p31)) {
                            // fill(metal);
                            // beam(p1.point, p32, rt);
                            // update corner table
                            AM.V[3*AM.nt] = p1.vid;
                            CT[3*AM.nt] = -1;
                            AM.V[AM.n(3*AM.nt)] = p2.vid;
                            CT[AM.n(3*AM.nt)] = 0;
                            AM.V[AM.p(3*AM.nt)] = AM.V[c3];
                            CT[AM.p(3*AM.nt)] = 1;
                            AM.V[c2] = p1.vid;
                            CT[c2] = -1;
                            CT[c3] = -1;
                            CT[c1] = 0;
                        } else {
                            // fill(metal);
                            // beam(p2.point, p31, rt);
                            // update corner table
                            AM.V[3*AM.nt] = p1.vid;
                            CT[3*AM.nt] = 0;
                            AM.V[AM.n(3*AM.nt)] = p2.vid;
                            CT[AM.n(3*AM.nt)] = -1;
                            AM.V[AM.p(3*AM.nt)] = AM.V[c1];
                            CT[AM.p(3*AM.nt)] = 1;
                            AM.V[c2] = p2.vid;
                            CT[c2] = -1;
                            CT[c1] = -1;
                            CT[c3] = 0;
                        }
                        // update counts
                        AM.nt += 2;
                        AM.nc += 6;
                    }
                }
            }
        }
        return fatEdgeDone;
    }

    void Compute () {
        initiate();
        // println("SHOWING STABS");
        // Use TRACER Stabs to Construct the new Edges
        for (int c = 0; c < M.nt; c++) {
            // Get the Corners for this Triangle
            int c1 = 3*c;
            int c2 = M.n(c1), c3 = M.n(M.n(c1));
            // Get the stabs at these corners
            // println(i, c1, TRACER.stabs.get(c1).size(), TRACER.stabs.get(c2).size(), TRACER.stabs.get(c3).size());
            // Draw a fat edge aligned to the trace
            boolean fatEdgeDone = false;
            int fc = -1, sc = -1, tc = -1;
            if (!fatEdgeDone) {
                fatEdgeDone = ComputeFATM(c1, c2, c3);
            }
            if (!fatEdgeDone) {
                fatEdgeDone = ComputeFATM(c2, c3, c1);
            }
            if (!fatEdgeDone) {
                fatEdgeDone = ComputeFATM(c3, c1, c2);   
            }
        }
        // println("FAT Mesh Triangles", AM.nt);
        AM.computeO();
        validity = new int[FMESH.AM.nc];
        for (int i = 0; i < FMESH.AM.nc; i++) {
            validity[i] = 1;
        }
    }

    void Show () {
        for (int i = 0; i < AM.nt; i++) {
            int c1 = 3*i, c2 = AM.n(c1), c3 = AM.p(c1);
            if (validity[c1] == 1 && validity[c2] == 1 && validity[c3] == 1) {
                pt v1 = AM.g(c1), v2 = AM.g(c2), v3 = AM.g(c3);
                pt ct = P(v1, v2, v3);
                pt p1 = P(v1, 0.3, ct), p2 = P(v2, 0.3, ct), p3 = P(v3, 0.3, ct);

                // display spheres
                if (AM.v(c1) < M.nv) fill(green); else fill(black);
                sphere(v1, 2*rt);
                if (AM.v(c2) < M.nv) fill(green); else fill(black);
                sphere(v2, 2*rt);
                if (AM.v(c3) < M.nv) fill(green); else fill(black);
                sphere(v3, 2*rt);

                if (c1 == AM.c) {
                    fill(magenta);
                    sphere(p1, 1.5*rt);
                } else {
                    fill(orange);
                    sphere(p1, rt);  
                }
                if (c2 == AM.c) {
                    fill(magenta);
                    sphere(p2, 1.5*rt);
                } else {
                    fill(orange);
                    sphere(p2, rt);  
                }
                if (c3 == AM.c) {
                    fill(magenta);
                    sphere(p3, 1.5*rt);
                } else {
                    fill(orange);
                    sphere(p3, rt);                
                }

                fill(GetEdgeColor(c1, c2, c3));
                beam(v1, v2, rt);
                fill(GetEdgeColor(c2, c3, c1));
                beam(v2, v3, rt);
                fill(GetEdgeColor(c3, c1, c2));
                beam(v3, v1, rt);
            }
        }
        CountNarrowTriangles();
    }

    color GetEdgeColor(int c1, int c2, int c3) {
        if (AM.o(c3) == c3) {
            return red;
        }
        if (CT[c3] == -1) {
            return yellow;
        } else if (CT[c3] == 1) {
            return magenta; 
        } else {
            return metal;
        }
    }
}