︠a0da2ef7-7d82-4b78-8df6-af4de89ac4deundefnedas︠
%auto
from collections import deque
︡55cc07ca-7457-4f72-9c83-09be7781ed99︡{"done":true}
︠624aa556-afe1-459a-a4b7-3e457ee68429undefnedas︠
%auto
def twosplit(G):
    Gi=[]
    bonds=graphs.EmptyGraph()
    bonds.allow_multiple_edges(True)
    H=copy(G)
    cut=H.vertex_connectivity(value_only=False)[1] ### find the vertices of a 2-split ###
    f=(cut[0],cut[1])
    H.delete_vertices(cut)
    CC=H.connected_components_subgraphs()
    for K in CC:
        L=G.subgraph(vertices=cut+K.vertices())
        L.allow_multiple_edges(True)
        if not cut[0] in L[cut[1]]: ### if the split vertices are not adjacent in the original graph, add an edge between them in each subgraph created by the split ###
            L.add_edge(f)
        Gi.append(L)
    if f in G.edges(labels=False): ### if the split vertices are adjacent in the original graph, we add a bond consisting of one more edge than the number of blocks 2-summed over the hinge ###
        for i in range(len(CC)+1):
            bonds.add_edge(f)
    elif len(CC)>2: ### if the split vertices are not adjacent in the original graph, there is a bond between these two vertices if and only if more than two blocks are 2-summed over the hinge###
        for i in range(len(CC)):
            bonds.add_edge(f)
    return [Gi,bonds,f]
︡649c9c18-ffe8-4d46-b8d0-c9847de3478a︡{"done":true}
︠cfa5c80f-0c08-4aa4-a590-f3c002d6d62bundefnedas︠
%auto
def Tuttedecomp(G):
    thblocks=[]
    twblocks=[]
    bonds=graphs.EmptyGraph()
    bonds.allow_multiple_edges(True)
    cuts=graphs.EmptyGraph()
    Tree=graphs.EmptyGraph()
    cycles=[]
    A=copy(G)
    if A.vertex_connectivity<2:
        return "This function is only implemented for 2-connected graphs"
    for e in A.edges():
        if A.subgraph(edges=[e]).has_multiple_edges(): ###testing vertex connectivity requires no multiple edges; also begin collecting bonds with the multiple edges removed from the graph###
            bonds.add_edge(e)
            f=(e[0],e[1])
            while f in A.edges(labels=False):
                bonds.add_edge(f)
                A.delete_edge(f)
            A.add_edge(f)
            cuts.add_edge(f)
    if A.is_isomorphic(graphs.CycleGraph(len(A))): ### if the original graph is a cycle or 3-connected, add it to the list of 3-blocks ###
        thblocks.append(A)
    elif A.vertex_connectivity()>2:
        thblocks.append(A)
    elif A.vertex_connectivity()==2:  ### if the original graph has a 2-separation, use it to start the list of 2-connected parts ###
        twblocks.append(A)
    while twblocks<>[]: ### eventually a 2-connected graph will be reduced to 3-blocks, so this list will be empty ###
        nextblocks=[]
        for B in twblocks:
            S=twosplit(B) ### split each graph with a 2-separation at its hinge ###
            for K in S[0]:
                if K.is_isomorphic(graphs.CycleGraph(len(K))): ### if one side of a 2-separation is a cycle, add that cycle minor to a list of cycles, which may need to be 2-summed as the twosplit algorithm may triangulate them ###
                    cycles.append(K)
                elif K.vertex_connectivity()==2:   ### if one side of a 2-separation has a 2-separation, add that 2-connected minor to a replacement list of minors to be 2-split ###
                    nextblocks.append(K)
                elif K.vertex_connectivity()>2:    ### if one side of a 2-separation is 3-connected, add that 3-connected minor to the list of 3-blocks ###
                    thblocks.append(K)
                elif K.vertex_connectivity()<2:
                    return "Something's wrong"
            bonds.add_edges(S[1].edges()) ### if the hinge vertices are adjacent in G, or if the split leaves more than two components, twosplit gives a parallel class used to 2-sum the minors and reconstruct the original graph around the hinge vertices ###
            cuts.add_edge(S[2]) ### store the hinge, to describe the location of an edge in the edge-sum tree (or an edge over which we 2-sum to restore a cycle 3-block) ###
        twblocks=nextblocks
    C=graphs.EmptyGraph()
    C.allow_multiple_edges(True)
    for B in cycles: ### undo triangulation of cycles ###
        C.add_edges(B.edges())
    for e in C.edges(labels=False):
        if C.subgraph(edges=[e]).has_multiple_edges(): ### a multiple edge in this graph is an edge over which two cycles are 2-summed; if it is not a bond edge, we 2-sum the cycles that share this edge to make a bigger cycle ###
            if not e in bonds.edges(labels=False):
                f=(e[0],e[1])
                cuts.delete_edge(f)
                while f in C.edges(labels=False):
                    C.delete_edge(f)
    bad=[] ### this will be the collection of cycles that share a vertex (or two) that we separate to determine the cycle 3-blocks ###
    cycles=[] ### here we collect the full cycles we extract ###
    for B in C.connected_components_subgraphs():
        for D in B.blocks_and_cut_vertices()[0]:
            bad.append(C.subgraph(vertices=D))
    while bad<>[]:
        newbad=[]
        for b in bad:
            for e in b.edges():
                if b.subgraph(edges=[e]).has_multiple_edges(): ### here two cycles are joined at a bond; we have already 2-summed all the smaller cycles generated by twosplit ###
                    f=(e[0],e[1])
                    while f in b.edges(labels=False): ### replace the bond edges with a single edge ###
                        b.delete_edge(f)
                    b.add_edge(f)
                    c=copy(b)
                    c.delete_vertices([e[0],e[1]])
                    for d in c.connected_components_subgraphs():
                        if d.has_multiple_edges(): ### this component still has the cycle we are examining attached to another cycle at a bond; we will separate them later ###
                            f=(e[0],e[1])
                            B=b.subgraph(vertices=d.vertices()+[e[0],e[1]])
                            while f in B.edges(labels=False):
                                B.delete_edge(f)
                            B.add_edge(f)
                            newbad.append(B)
                        else: ### in this case we have a cycle 3-block fully separated from the rest of the graph ###
                            f=b.subgraph(vertices=d.vertices()+[e[0],e[1]])
                            f.allow_multiple_edges(False)
                            cycles.append(f)
        bad=newbad
    thblocks=thblocks+cycles ### now we have identified all cycle 3-blocks, so we add them to the list ###
    Treeverts=[] ### as with blocks_and_cuts_tree, we name vertices of the edge-sum tree with a type (bond, cycle or three-block) and the list of vertices of G in this block, noting only bonds have multiple edges ###
    for T in thblocks:
        if len(T)==2:
            str='B'
        elif T.is_isomorphic(graphs.CycleGraph(len(T))):
            str='C'
        else:
            str='T'
        Treeverts.append((str,tuple(T.vertices())))
    for e in cuts.edges(labels=False): ### create links in edge-sum tree; if multiple cycles or 3-connected 3-blocks share an edge, those blocks have links to a bond node, not each other ###
        if e in bonds.edges(labels=False):
            for i in range(len(thblocks)):
                if e in thblocks[i].edges(labels=False):
                    Tree.add_edge(('B',(e[0],e[1])),Treeverts[i])
        else:
            for i in range(len(thblocks)):
                if e in thblocks[i].edges(labels=False):
                    for j in range(i+1,len(thblocks)):
                        if e in thblocks[j].edges(labels=False):
                            Tree.add_edge(Treeverts[i],Treeverts[j])
    thcomps=copy(thblocks)
    bondnames=copy(bonds)
    bondnames.allow_multiple_edges(False) ### iterate through all the parallel classes to create bonds corresponding to bond nodes for the list of 3-blocks ###
    for p in bondnames.edges(labels=False):
        f=(p[0],p[1])
        bondnames=copy(bonds)
        PC=graphs.EmptyGraph()
        PC.allow_multiple_edges(True)
        while f in bonds.edges(labels=False):
            bonds.delete_edge(f)
            PC.add_edge(f)
        thblocks.append(PC)
    return [thcomps,thblocks,bonds,Tree]
︡67fdfa3c-8aa6-45d8-87c7-8a439f6e641d︡{"done":true}
︠8ecb31f8-90ca-40cc-b39b-01e79df9aabfundefnedasr︠
%auto
def K5switch(H,Kur):
    H.allow_multiple_edges(False)
    b='None'
    for v in Kur:
        if Kur.degree(v)==2:
            b=v
            break
    K33edge=[]
    hold=[]
    nbredges=[[],[],[],[]]
    if b=='None':
        for v in H:
            if not v in Kur:
                b=v
                blue=[v]
                break
        red=[]
        PS=H.disjoint_routed_paths([(b,Kur.vertices()[i]) for i in range(3)])
        for i in range(3):
            path=PS[i].shortest_path(b,Kur.vertices()[i])
            for j in range(len(path)):
                if not path[j] in Kur:
                    K33edge.append((path[j],path[j+1]))
                else:
                    red.append(path[j])
                    break
        for v in Kur:
            if v not in blue:
                if v not in red:
                    blue.append(v)
        G=copy(Kur)
        for i in [1,2]:
            for v in G[blue[i]]:
                hold.append((blue[i],v))
                u=v
                G.delete_edge(blue[i],u)
                while Kur.degree(u)<4:
                    w=G[u][0]
                    hold.append((u,w))
                    G.delete_edge(u,w)
                    u=w
                if u in red:
                    K33edge=K33edge+hold
                hold=[]
        T=graphs.EmptyGraph()
        T.add_edges(K33edge)
        return T
    else:
        G=copy(Kur)
        v=b
        for i in range(2):
            u=Kur[b][i]
            K33edge.append((u,b))
            G.delete_edge(u,b)
            nbredges[0].append(u)
            while Kur.degree(u)<4:
                f=G.edges_incident(u)[0]
                v=G[u][0]
                K33edge.append((u,v))
                G.delete_edge(f)
                u=v
                nbredges[0].append(u)
            nbredges[0].remove(u)
            nbredges[1].append(u)
        red=copy(nbredges[1])
        J=copy(H)
        J.delete_vertices(red)
        for v in Kur:
            #if v in J: #commented out 5/26/16 - believe this was source of exceptions#
            if v in J and v!=b: ###5/26/16 better, but not enough###
                if J.degree(v)>0:
                    path=J.shortest_path(b,v)
                    break
        for v in path:
            if v in nbredges[0]:
                b=v
        for i in range(len(path)):
            if path[i]==b:
                p=path[i:]
                break
        for i in range(1,len(p)):
            if p[i] in Kur:
                path=p[:i+1]
                break
        blue=[b]
        r=path[-1]
        for i in range(len(path)-1):
            K33edge.append((path[i],path[i+1]))
        if Kur.degree(r)==4:
            for v in Kur:
                if Kur.degree(v)==4:
                    if v not in blue:
                        if v not in red:
                            blue.append(v)
            hold=[]
            for i in [1,2]:
                for e in G.edges_incident(blue[i]):
                #for e in Kur.edges_incident(blue[i]):
                    if e[0]==blue[i]:
                        u=e[1]
                    else:
                        u=e[0]
                    hold.append(e)
                    G.delete_edge(e)
                    while Kur.degree(u)<4:
                        e=G.edges_incident(u)[0]
                        v=G[u][0]
                        hold.append(e)
                        u=v
                    if u in red:
                        K33edge=K33edge+hold
                    hold=[]
        else:
            hold=[]
            maybe=[]
            for i in range(2):
                u=Kur[r][i]
                hold.append((r,u))
                G.delete_edge(r,u)
                while Kur.degree(u)<4:
                    f=G.edges_incident(u)[0]
                    v=G[u][0]
                    hold.append((u,v))
                    G.delete_edge(f)
                    u=v
                if u in nbredges[1]:
                    case=2
                else:
                    maybe.append(u)
                    K33edge=K33edge+hold
                hold=[]
            if case==2:
                red.append(maybe[0])
                for v in Kur:
                    if Kur.degree(v)==4:
                        if v not in blue:
                            if v not in red:
                                blue.append(v)
                for i in [1,2]:
                    for e in G.edges_incident(blue[i]):
                        if e[0]==blue[i]:
                            u=e[1]
                        else:
                            u=e[0]
                        hold.append((blue[i],u))
                        G.delete_edge(e)
                        while Kur.degree(u)<4:
                            e=G.edges_incident(u)[0]
                            v=G[u][0]
                            hold.append((u,v))
                            u=v
                        if u in red:
                            K33edge=K33edge+hold
                        hold=[]
            else:
                red.append(r)
                blue=blue+maybe
                for i in [1,2]:
                    for e in Kur.edges_incident(blue[i]):
                        if e[0]==blue[i]:
                            u=e[1]
                        else:
                            u=e[0]
                        hold.append((blue[i],u))
                        G.delete_edge(e)
                        while Kur.degree(u)<4:
                            e=G.edges_incident(u)[0]
                            v=G[u][0]
                            hold.append((u,v))
                            u=v
                        if u in red:
                            K33edge=K33edge+hold
                        hold=[]
            T=graphs.EmptyGraph()
            T.add_edges(K33edge)
            return T
︡fea4f830-b081-4447-9a94-e1ba06bca171︡{"done":true}
︠bd438a27-50ba-49cf-8575-0b5f5cdc8576sw︠
%auto
def K5switchnewer(H,Kur):
    H.allow_multiple_edges(False)
    b='None'
    case='None'
    for v in Kur:
        if Kur.degree(v)==2:
            b=v
            break
    K33edge=[]
    nbredges=[[],[],[],[]]
    hold=[]
    if b=='None': ###in this case the Kuratowski subgraph is isomorphic to K5###
        for v in H:
            if not v in Kur:
                b=v
                blue=[v]
                break
        red=[]
        PS=H.disjoint_routed_paths([(b,Kur.vertices()[i]) for i in range(3)])
        for i in range(3):
            path=PS[i].shortest_path(b,Kur.vertices()[i])
            for j in range(len(path)):
                if not path[j] in Kur:
                    K33edge.append((path[j],path[j+1]))
                else:
                    red.append(path[j])
                    break
        for v in Kur:
            if v not in blue:
                if v not in red:
                    blue.append(v)
        G=copy(Kur)
        for i in [1,2]:
            for v in G[blue[i]]:
                hold.append((blue[i],v))
                u=v
                G.delete_edge(blue[i],u)
                while Kur.degree(u)<4:
                    w=G[u][0]
                    hold.append((u,w))
                    G.delete_edge(u,w)
                    u=w
                if u in red:
                    K33edge=K33edge+hold
                hold=[]
        T=graphs.EmptyGraph()
        T.add_edges(K33edge)
        return T
    else: ###here the Kuratowski subgraph is a subdivision of K5, and this case is throwing exceptions###
        G=copy(Kur)
        v=b
        for i in range(2):
            u=Kur[b][i]
            K33edge.append((u,b))
            G.delete_edge(u,b)
            nbredges[0].append(u)
            while Kur.degree(u)<4:
                f=G.edges_incident(u)[0]
                v=G[u][0]
                K33edge.append((u,v))
                G.delete_edge(f)
                u=v
                nbredges[0].append(u)
            nbredges[0].remove(u)
            nbredges[1].append(u)
        red=copy(nbredges[1])
        J=copy(H)
        J.delete_vertices(red)
        for v in Kur:
            if v in J and v!=b and v not in nbredges[0]:
                if J.degree(v)>0:
                    path=J.shortest_path(b,v)
                    break
        for v in path:
            if v in nbredges[0]:
                b=v
        for i in range(len(path)):
            if path[i]==b:
                p=path[i:]
                break
        if len(p)>1:
            for i in range(1,len(p)):
                if p[i] in Kur:
                    path=p[:i+1]
                    break
        blue=[b]
        r=path[-1]
        red.append(r)
        for i in range(len(path)-1):
            K33edge.append((path[i],path[i+1]))
        if Kur.degree(r)==4:
            for v in Kur:
                if Kur.degree(v)==4:
                    if v not in blue:
                        if v not in red:
                            blue.append(v)
            hold=[]
            for i in [1,2]:
                for e in G.edges_incident(blue[i]):
                #for e in Kur.edges_incident(blue[i]):
                    if e[0]==blue[i]:
                        u=e[1]
                    else:
                        u=e[0]
                    hold.append((e[0],e[1]))
                    G.delete_edge(e)
                    while Kur.degree(u)<4:
                        e=G.edges_incident(u)[0]
                        v=G[u][0]
                        hold.append((e[0],e[1]))
                        u=v
                    if u in red:
                        K33edge=K33edge+hold
                    hold=[]
        else:
            hold=[]
            maybe=[]
            for i in range(2):
                u=Kur[r][i]
                hold.append((r,u))
                G.delete_edge(r,u)
                while Kur.degree(u)<4:
                    f=G.edges_incident(u)[0]
                    v=G[u][0]
                    hold.append((u,v))
                    G.delete_edge(f)
                    u=v
                if u in nbredges[1]:
                    case=2
                else:
                    maybe.append(u)
                    K33edge=K33edge+hold
                hold=[]
            if case==2:
                red.append(maybe[0])
                for v in Kur:
                    if Kur.degree(v)==4:
                        if v not in blue:
                            if v not in red:
                                blue.append(v)
                for i in [1,2]:
                    for e in G.edges_incident(blue[i]):
                        if e[0]==blue[i]:
                            u=e[1]
                        else:
                            u=e[0]
                        hold.append((blue[i],u))
                        G.delete_edge(e)
                        while Kur.degree(u)<4:
                            e=G.edges_incident(u)[0]
                            v=G[u][0]
                            hold.append((u,v))
                            u=v
                        if u in red:
                            K33edge=K33edge+hold
                        hold=[]
            else:
                #red.append(r)
                blue=blue+maybe
                for i in range(1,3):
                    for e in G.edges_incident(blue[i]):
                        if e[0]==blue[i]:
                            u=e[1]
                        else:
                            u=e[0]
                        hold.append((blue[i],u))
                        G.delete_edge(e)
                        while Kur.degree(u)<4:
                            e=G.edges_incident(u)[0]
                            v=G[u][0]
                            hold.append((u,v))
                            u=v
                        if u in red:
                            K33edge=K33edge+hold
                        hold=[]
        T=graphs.EmptyGraph()
        T.add_edges(K33edge)
        return T
︡469b460b-0892-426d-af4e-e6d676d7c468︡{"done":true}
︠bd883233-7d16-40ec-a37d-5b27e360579dundefnedasw︠
%auto
def K33cycle(H):
    G=copy(H)
    kupath=[]
    matching_edges=[]
    branch_vertices=[]
    for v in G:
        if G.degree(v)==3:
            new=1
            branch_vertices.append(v)
            for i in range(3):
                if G.degree(v)<3:
                    break
                new=1
                u=v
                e=G.edges_incident(u)[i]
                kupath.append(e)
                a=e[0]
                b=e[1]
                G.delete_edge(e)
                if a==u:
                    u=b
                else:
                    u=a
                while u not in branch_vertices:
                    if G.degree(u)==2:
                        matching_edges.append(kupath)
                        branch_vertices.append(u)
                        kupath=[]
                        new=0
                        break
                    else:
                        e=G.edges_incident(u)[0]
                        kupath.append(e)
                        a=e[0]
                        b=e[1]
                        G.delete_edge(e)
                        if a==u:
                            u=b
                        else:
                            u=a
                if u in branch_vertices:
                    if new==1:
                        G.add_edges(kupath)
                    kupath=[]
    for v in G:
        if G.degree(v)==0:
            G.delete_vertex(v)
    return G.hamiltonian_cycle(algorithm='backtrack')[1]
︡f5778b55-8212-4e74-8ac6-094950f91182︡{"done":true}
︠0a276f7e-b757-4a8b-8417-105ee70a5c07undefnedasw︠
%auto
def is_projective(G,pp_embedding=0):
    #This function currently does not return multiple edges in the embedding scheme. This may be a byproduct of the use of is_planar to obtain rotation systems for each of the Kuratowski faces
    bad=0
    n=len(G.vertices())
    m=len(G.edges())
    if m>3*n-3:
        return "The graph has more than 3n-3 edges" # the graph violates the upper bound on number of edges for embeddability in the projective plane
    if G.is_planar(): # test for planarity - if the graph embeds on the plane, it certainly embeds on the projective plane
        H=G.is_planar(set_embedding=True)
        output=['The graph is planar',G.get_embedding()]
        return output
    trips=[]
    for CC in G.connected_components_subgraphs():
        for Bl in CC.blocks_and_cut_vertices()[0]:
            trips=trips+Tuttedecomp(G.subgraph(Bl))[0]
    Kurs=[]
    for T in trips:
        if not T.is_planar():
            bad=bad+1
            #8 Feb 2016
            Kurs.append([T,T.is_planar(kuratowski=True)[1]])
            #/8 Feb 2016
            if bad==2:
                NE=graphs.EmptyGraph()
                NE.add_edges(Kurs[0][1].edges())
                NE.add_edges(T.edges())
                
                return "not projective", NE
            
    K=Kurs[0][1]
    ku=max(K.degree()) # we use this to separate cases for which Kuratowski subgraph requires an embedding on the projective plane
    if ku==4:
        if len(K)==5:
            return 1
        else:
            #K=K5switch(Kurs[0][0],Kurs[0][1]) commented out 5/26/16 for new K5switch function
            #K=K5switchnew(Kurs[0][0],K) commented out 5/26/16/ for yet newer K5switch function
            K=K5switchnewer(Kurs[0][0],K)
    ku=max(K.degree()) # update max degree of Kuratowski subdivision to reflect K5switch for error testing
    Ham=K33cycle(K) # We are restricting now to the case in which is_planar returns a subdivision of K_3,3 or K5switch was successful
    Kuratowski_vertices=[] # The vertices of degree >2 in the Kuratowski subgraph
    Kuratowski_edges=[]  # A collection of triples whose first two entries are adjacent vertices in the Kuratowski minor and whose third entry is the path between those vertices in the Kuratowski subgraph
    KK=K.copy()
    for i in range(len(Ham)):
        if K.degree(Ham[i])==ku: # Since Ham is a Hamilton cycle, this cycles through all the vertices of K, and extracts the branch vertices in order
            Kuratowski_vertices.append(Ham[i]) # list the vertices of the Kuratowski minor in an order so we can permute them to cover all labelings of an embedding
            kupath=[(Ham[i],Ham[mod(i+1,len(Ham))])] # build the path between consecutive vertices of the Hamilton cycle that are also vertices of the Kuratowski minor; these are the subdivisions of the Kuratowski minor's edges
            j=mod(i+1,len(Ham))
            while K.degree(Ham[j])==2:
                kupath.append((Ham[j],Ham[j+1]))
                j=mod(j+1,len(Ham))
            Kuratowski_edges.append([Ham[i],Ham[j],kupath]) # lists consecutive Kuratowski vertices in the Hamilton cycle and subdivision of the edge between them
            KK.delete_edges(kupath) # remove all the edges of the Hamilton cycle, leaving a matching if K was a K_3,3 subdivision or another Hamilton cycle if K was a K_5 subdivision
    bridges=KuraBridges(G,K)
   
    if ku==3: # Instructions if G has a subgraph isomorphic to a subdivision of K_3,3
        for i in range(len(KK.connected_components_subgraphs())): 
            if len(KK.connected_components_subgraphs()[i])<>1: # identify nontrivial connected components of K_3,3 minus the Hamilton cycle; these are a subdivision of a matching
                kupath=[]
                for v in KK.connected_components_subgraphs()[i]:
                    if KK.connected_components_subgraphs()[i].degree(v)==1: # should this be just a check for membership in Kuratowski vertices? Check which is faster.
                        kupath.append(v) # the endpoints of a component path are Kuratowski vertices
                Kuratowski_edges.append(kupath+[KK.connected_components_subgraphs()[i].edges()]) # makes explicit the Kuratowski vertices matched by this component, and the subdivision of the edge between them
        kv=Permutations([Kuratowski_vertices[1],Kuratowski_vertices[3],Kuratowski_vertices[5]]) # generate all permutations of a color class to generate all labelled embeddings of subdivision of K_3,3
        for i in range(len(kv)):
            kvs=[Kuratowski_vertices[0],kv[i][0],Kuratowski_vertices[2],kv[i][1],Kuratowski_vertices[4],kv[i][2]] #list all 6 orderings of the vertices of K_3,3 on a Hamilton cycle to generate the distinct embeddings
            faces=K33embeddings(K,Kuratowski_edges,kvs) #right now this just generates all the faces of the embeddings
            FA=FaceAssign(bridges,faces)
            if not FA==0:
                FEmb=copy(FA)
                Trips=[[],[],[]] # assign a type to each bridge that can be embedded in three faces
                for b in range(len(FEmb)):
                    if len(FEmb[b][2])==3:
                        if not 3 in FEmb[b][2]:
                            FType=0
                        elif not 2 in FEmb[b][2]:
                            FType=1
                        elif not 1 in FEmb[b][2]:
                            FType=2
                        if FType==0:
                            Trips[0].append(b)
                        elif FType==1:
                            Trips[1].append(b)
                        elif FType==2:
                            Trips[2].append(b)
                    
                for i in range(3):
                    FE=deepcopy(FEmb)
                    if len(Trips[i])>0:
                        for b in Trips[i]:
                            FE[b][2]=[0]
                    if len(Trips[(i+1)%3])>0:
                            for b in Trips[(i+1)%3]:
                                FE[b][2].remove(0)
                    if len(Trips[(i-1)%3])>0:
                            for b in Trips[(i-1)%3]:
                                FE[b][2].remove(0)
                    Assign=Conflicts(FE,faces)
                    if not Assign==0:
                        embeddings=[]
                        projective_embedding={}
                        outerfaces=deepcopy(faces)
                        for i in range(len(outerfaces)):
                            hub=len(G)+i+1
                            for v in outerfaces[i].vertices():
                                outerfaces[i].add_edge(hub,v)
                        for i in range(len(Assign)):
                            outerfaces[Assign[i][1]].add_edges(bridges[Assign[i][0]][0].edges())
                        for i in range(len(outerfaces)):
                            outerfaces[i].is_planar(set_embedding=True)
                            embe=deepcopy(outerfaces[i].get_embedding())
                            embeddings.append(embe)
                        #right now this is a list of embeddings in the plane for each of the faces of K_3,3#
                        #### New 31 Jan - add embeddings of faces using the crosscap to central face
                        Not=[]
                        for f in range(len(outerfaces)):
                            H=copy(outerfaces[f])
                            H.delete_edges(outerfaces[f].edges())
                            H.add_edges(faces[f].edges())
                            Not.append(H)
                        #for m in range(len(embeddings)): # end (if possible) the clockwise rotation of neighbors of vertices in face 0 with hub (if on a face of K_3,3)
                        for v in embeddings[0]:
                            if v in G:
                                for j in range(len(embeddings[0][v])):
                                    if embeddings[0][v][j] >=len(G):
                                        bounds=deque(embeddings[0][v])
                                        bounds.rotate(len(embeddings[0][v])-j-1)
                                        embeddings[0][v]=list(bounds)
                                        embeddings[0][v].remove(embeddings[0][v][-1])
                                        break
                        ###
                        #need to get the order of the neighbors of region 0's hub to match order of kvs
                        x=max(embeddings[0])
                        for i in range(len(embeddings[0][x])):
                            done=0
                            if embeddings[0][x][i] in kvs:
                                if done==1:
                                    break
                                for j in range(len(kvs)):
                                    if kvs[j]==embeddings[0][x][i]:
                                        t=j
                                        break
                                for k in range(i+1,len(embeddings[0][x])):
                                    if embeddings[0][max(embeddings[0])][k] in kvs:
                                        if not embeddings[0][x][k]==kvs[(t+1)%6]:
                                            done=1
                                            break
                                        else:
                                            for v in embeddings[0]:
                                                embeddings[0][v].reverse()
                                            done=1
                                            break
                        ###
                        for i in range(4):
                            for v in embeddings[i]:
                                if v>len(G):
                                    del embeddings[i][v]
                                    break
                        for i in range(1,4):
                            for v in embeddings[i]:
                                for n in embeddings[i][v]:
                                    if n>len(G):
                                        embeddings[i][v].remove(n)
                                        break
                        for v in embeddings[1]:
                            if v in kvs:
                                for j in range(len(embeddings[1][v])):
                                    if (v,embeddings[1][v][j]) in faces[3].edges(labels=False):
                                        bounds=deque(embeddings[1][v])
                                        bounds.rotate(-j)
                                        embeddings[1][v]=list(bounds)
                                        break
                                    elif (v,embeddings[1][v][j]) in faces[2].edges(labels=False):
                                        bounds=deque(embeddings[1][v])
                                        bounds.rotate(len(embeddings[1][v])-j-1)
                                        embeddings[1][v]=list(bounds)
                                        break
                            elif v in faces[0]:
                                for j in range(len(embeddings[1][v])):
                                    if embeddings[1][v][j]==embeddings[0][v][-1]:
                                        bounds=deque(embeddings[1][v])
                                        bounds.rotate(len(embeddings[1][v])-j-1)
                                        embeddings[1][v]=list(bounds)
                                        break
                            elif v in faces[2]:
                                for j in range(len(embeddings[1][v])):
                                    if embeddings[1][v][j] in embeddings[2][v]:
                                        if embeddings[1][v][(j-1)%len(embeddings[1][v])] not in embeddings[2][v]:
                                            bounds=deque(embeddings[1][v])
                                            bounds.rotate(len(embeddings[1][v])-j-1)
                                            embeddings[1][v]=list(bounds)
                                            break
                            elif v in faces[3]:
                                for j in range(len(embeddings[1][v])):
                                    if embeddings[1][v][j] in embeddings[3][v]:
                                        if embeddings[1][v][(j+1)%len(embeddings[1][v])] not in embeddings[3][v]:
                                            bounds=deque(embeddings[1][v])
                                            bounds.rotate(len(embeddings[1][v])-j-1)
                                            embeddings[1][v]=list(bounds)
                                            break
                        for v in embeddings[2]:
                            if v in kvs:
                                for j in range(len(embeddings[2][v])):
                                    if (v,embeddings[2][v][j]) in faces[1].edges(labels=False):
                                        bounds=deque(embeddings[2][v])
                                        bounds.rotate(-j)
                                        embeddings[2][v]=list(bounds)
                                        break
                                    elif (v,embeddings[2][v][j]) in faces[3].edges(labels=False):
                                        bounds=deque(embeddings[2][v])
                                        bounds.rotate(len(embeddings[2][v])-j-1)
                                        embeddings[2][v]=list(bounds)
                                        break
                            elif v in faces[0]:
                                for j in range(len(embeddings[2][v])):
                                    if embeddings[2][v][j]==embeddings[0][v][-1]:
                                        bounds=deque(embeddings[2][v])
                                        bounds.rotate(len(embeddings[2][v])-j-1)
                                        embeddings[2][v]=list(bounds)
                                        break
                            elif v in faces[3]:
                                for j in range(len(embeddings[2][v])):
                                    if embeddings[2][v][j] in embeddings[3][v]:
                                        if embeddings[2][v][(j-1)%len(embeddings[2][v])] not in embeddings[3][v]:
                                            bounds=deque(embeddings[2][v])
                                            bounds.rotate(len(embeddings[2][v])-j-1)
                                            embeddings[2][v]=list(bounds)
                                            break
                            elif v in faces[1]:
                                for j in range(len(embeddings[2][v])):
                                    if embeddings[2][v][j] in embeddings[1][v]:
                                        if embeddings[2][v][(j+1)%len(embeddings[2][v])] not in embeddings[1][v]:
                                            bounds=deque(embeddings[2][v])
                                            bounds.rotate(len(embeddings[2][v])-j-1)
                                            embeddings[2][v]=list(bounds)
                                            break
                        for v in embeddings[3]:
                            if v in kvs:
                                for j in range(len(embeddings[3][v])):
                                    if (v,embeddings[3][v][j]) in faces[2].edges(labels=False):
                                        bounds=deque(embeddings[3][v])
                                        bounds.rotate(-j)
                                        embeddings[3][v]=list(bounds)
                                        break
                                    elif (v,embeddings[3][v][j]) in faces[1].edges(labels=False):
                                        bounds=deque(embeddings[3][v])
                                        bounds.rotate(len(embeddings[3][v])-j-1)
                                        embeddings[3][v]=list(bounds)
                                        break
                            elif v in faces[0]:
                                for j in range(len(embeddings[3][v])):
                                    if embeddings[3][v][j]==embeddings[0][v][-1]:
                                        bounds=deque(embeddings[3][v])
                                        bounds.rotate(len(embeddings[3][v])-j-1)
                                        embeddings[3][v]=list(bounds)
                                        break
                            elif v in faces[1]:
                                for j in range(len(embeddings[3][v])):
                                    if embeddings[3][v][j] in embeddings[1][v]:
                                        if embeddings[3][v][(j-1)%len(embeddings[3][v])] not in embeddings[1][v]:
                                            bounds=deque(embeddings[3][v])
                                            bounds.rotate(len(embeddings[3][v])-j-1)
                                            embeddings[3][v]=list(bounds)
                                            break
                            elif v in faces[2]:
                                for j in range(len(embeddings[3][v])):
                                    if embeddings[3][v][j] in embeddings[3][v]:
                                        if embeddings[3][v][(j+1)%len(embeddings[3][v])] not in embeddings[2][v]:
                                            bounds=deque(embeddings[3][v])
                                            bounds.rotate(len(embeddings[3][v])-j-1)
                                            embeddings[3][v]=list(bounds)
                                            break
                    #i=0
                                    #while m[v][i] in G:
                                    #    i=i+1
                                    #    if i==len(m[v]):
                                    #        break
                                    #order=deque(m[v])
                                    #order.rotate(0-i)
                                    #m[v]=list(order)
                                    #if not m[v][0] in G:
                                    #    m[v].remove(m[v][0])
                        #we believe the above (up to fixing K5switch 7 Feb 2016)        
                        #print kvs,embeddings
                        for v in outerfaces[0]:
                            if v in G:
                                projective_embedding[v]=embeddings[0][v]
                                for n in embeddings[0][v]:
                                    if not n in projective_embedding[v]:
                                        projective_embedding[v].append(n)
                                        for j in range(1,4):
                                            if (v,n)in outerfaces[j].edges(labels=False):
                                                i=0
                                                while embeddings[j][v][i]<>n:
                                                    i=i+1
                                                i=(i+1)%len(embeddings[j][v])
                                                while embeddings[j][v][i]<>n:
                                                    projective_embedding[v].append(embeddings[j][v][i])
                                                    i=(i+1)%len(embeddings[j][v])
                                    
                        #print 'line 652'
                        #print embeddings
                        #print projective_embedding
                        #print 'make no changes above line 655'
                        #### /New 31 Jan
                        for v in [kvs[0],kvs[3]]:
                            for f in [0,3,1]:
                                if not v in projective_embedding:
                                    projective_embedding[v]=copy(embeddings[f][v])
                                else:
                                    for n in embeddings[f][v]:
                                        if n < len(G):
                                            if not n in projective_embedding[v]:
                                                projective_embedding[v].append(n)
                        for e in embeddings:
                            for v in e:
                                if v < len(G):
                                    if not v in projective_embedding:
                                        projective_embedding[v]=copy(e[v])
                                    else:
                                        for n in e[v]:
                                            if n < len(G):
                                                if not n in projective_embedding[v]:
                                                    projective_embedding[v].append(n)
                        for v in projective_embedding:
                            for n in projective_embedding[v]:
                                if not n<len(G):
                                    projective_embedding[v].remove(n)
                        rotation_system={}
                        for v in projective_embedding:
                            rotation_system[v]=[]
                        XCapKurVerts=[]
                        Face0=faces[0].hamiltonian_cycle(algorithm='backtrack')[1]
                        half=0
                        t=0
                        while Face0[t] not in kvs:
                            t=t+1
                        while half<4:
                            if Face0[t] in kvs:
                                half=half+1
                            if half<4:
                                XCapKurVerts.append(Face0[t])
                            t=t+1
                        #print projective_embedding
                        #print XCapKurVerts
                        for v in projective_embedding:
                            ######new
                            for n in projective_embedding[v]:
                                if v in XCapKurVerts or n in XCapKurVerts:
                                    if not (n,v) in outerfaces[0].edges(labels=False):
                                        if not (v,n) in outerfaces[0].edges(labels=False):
                                            rotation_system[v].append((n,-1))
                                        else:
                                            rotation_system[v].append((n,1))
                                    else:
                                        rotation_system[v].append((n,1))
                                else:
                                    rotation_system[v].append((n,1))
                        if pp_embedding==0:
                            return 1
                        elif pp_embedding==1:
                            return 1,rotation_system
        return "not projective"
︡14e1909f-d835-4714-bdc8-30cc09abd1ed︡{"done":true}
︠6f66f0d3-c977-4261-8ed0-50052febf3c1undefnedasw︠
%auto
def K33embeddings(K,Kuratowski_edges,Kuratowski_vertices):
    FF=graphs.EmptyGraph()
    for i in range(len(Kuratowski_vertices)):
        for e in range(len(Kuratowski_edges)):
            if Set([Kuratowski_edges[e][0],Kuratowski_edges[e][1]])==Set([Kuratowski_vertices[i],Kuratowski_vertices[mod(i+1,len(Kuratowski_vertices))]]):
                FF.add_edges(Kuratowski_edges[e][2])
                break
    faces=[FF.copy()] #This is face 0 from Myrvold and Roth's paper, a Hamilton cycle of K_3,3 (but not necessarily the subdivision)
    KK=K.copy()
    KK.delete_edges(FF.edges()) # deleting the edges of a Hamilton cycle leaves a matching; since we reordered the vertices we mimic how we identified the subdivision of the edges of the Kuratowski minor
    for i in range(3):
        FFN=graphs.EmptyGraph()
        for e in range(len(Kuratowski_edges)):
            if Set([Kuratowski_edges[e][0],Kuratowski_edges[e][1]])==Set([Kuratowski_vertices[i],Kuratowski_vertices[mod(i+1,len(Kuratowski_vertices))]]):
                FFN.add_edges(Kuratowski_edges[e][2])
            if Set([Kuratowski_edges[e][0],Kuratowski_edges[e][1]])==Set([Kuratowski_vertices[mod(i+3,len(Kuratowski_vertices))],Kuratowski_vertices[mod(i+4,len(Kuratowski_vertices))]]):
                FFN.add_edges(Kuratowski_edges[e][2])
        for j in range(len(KK.connected_components_subgraphs())):
            if Kuratowski_vertices[i] in KK.connected_components_subgraphs()[j]:
                FFN.add_edges(KK.connected_components_subgraphs()[j].edges()) # the subdivision of one of the edges crossing the boundary
            if Kuratowski_vertices[i+1] in KK.connected_components_subgraphs()[j]:
                FFN.add_edges(KK.connected_components_subgraphs()[j].edges()) # the subdivision of one of the edges crossing the boundary
        faces.append(FFN.copy())
    return faces
︡f66b5702-7250-4c6e-a3ea-8428a044b11a︡{"done":true}
︠2ada135b-81c3-417f-944b-2ba88ff39c5dundefnedasw︠
%auto
def K5embeddings1(K,Kuratowski_edges,Kuratowski_vertices):
    FF=graphs.EmptyGraph()
    for i in range(len(Kuratowski_vertices)):
        for e in range(len(Kuratowski_edges)):
            if Set([Kuratowski_edges[e][0],Kuratowski_edges[e][1]])==Set([Kuratowski_vertices[i],Kuratowski_vertices[mod(i+1,len(Kuratowski_vertices))]]):
                FF.add_edges(Kuratowski_edges[e][2])
                break
    faces=[FF.copy()] # This is face 0 from the embedding in which one face of the K_5 embedding is a Hamilton cycle
    for i in range(len(Kuratowski_vertices)):
        FFN=graphs.EmptyGraph()
        faceverts=Set([Kuratowski_vertices[i],Kuratowski_vertices[mod(i+1,len(Kuratowski_vertices))],Kuratowski_vertices[mod(i+3,len(Kuratowski_vertices))]]) # the edges on the remaining faces are the triangles that include exactly one edge from face 0
        for e in range(len(Kuratowski_edges)):
            if Set([Kuratowski_edges[e][0],Kuratowski_edges[e][1]]).issubset(faceverts):
                FFN.add_edges(Kuratowski_edges[e][2])
        faces.append(FFN.copy())
    return faces
︡e2c8d9a0-76bb-4bda-b259-33b567e88ff8︡{"done":true}
︠9387daf0-62e6-41fe-982d-ac62c0845ef1undefnedasw︠
%auto
def K5embeddings2(K,Kuratowski_edges,Kuratowski_vertices,faceverts):
    faces=[]
    c=Set(Kuratowski_vertices).symmetric_difference(Set(faceverts))
    for j in range(len(faceverts)):
        FFN=graphs.EmptyGraph()
        for e in range(len(Kuratowski_edges)):
            if set([Kuratowski_edges[e][0],Kuratowski_edges[e][1]]).issubset(Set([faceverts[j],faceverts[mod(j+1,len(faceverts))],c[0]])):
                FFN.add_edges(Kuratowski_edges[e][2])
        faces.append(FFN.copy())
    for j in range(2):
        FFN=graphs.EmptyGraph()
        for e in range(len(Kuratowski_edges)):
            if not Set([Kuratowski_edges[e][0],Kuratowski_edges[e][1]])==Set([faceverts[j],faceverts[mod(j-1,len(faceverts))]]):
                if not Set([Kuratowski_edges[e][0],Kuratowski_edges[e][1]])==Set([faceverts[mod(j+1,len(faceverts))],faceverts[mod(j-2,len(faceverts))]]):
                    if not c[0] in [Kuratowski_edges[e][0],Kuratowski_edges[e][1]]:
                        FFN.add_edges(Kuratowski_edges[e][2])
        faces.append(FFN.copy())
    return faces
︡73cef621-f5c6-4dac-8b6b-baa5884c98f2︡{"done":true}
︠7228ae41-da4a-4800-ae1c-7968dbe87506undefnedasw︠
%auto
def KuraBridges(G,K): # input a graph G and a subgraph K that is a subdivision of a Kuratowski minor
    KK=G.copy()
    KK.delete_vertices(K.vertices()) # leaves components that are nontrivial bridges missing their connecting edges
    CC=[]
    for i in range(len(KK.connected_components_subgraphs())):
        CC.append([KK.connected_components_subgraphs()[i],[]]) # will append to each entry the list of its feet in the Kuratowski subdivision
    EE=G.copy() #create a copy of the original graph so we can isolate the edges that connect the bridges to the Kuratowski subdivision
    EE.delete_edges(K.edges()) # delete the edges of the Kuratowski subgraph
    EE.delete_edges(KK.edges()) # delete the edges incident to vertices on bridges but not the Kuratowski subdivision
    Legs=EE.edges() # these are the single-edge bridges and the edges connecting bridges to the Kuratowski subdivision
    SingleEdgeBridges=EE.copy()
    for L in range(len(Legs)):
        if not Legs[L][0] in K: # checks whether the first vertex incident to this edge is in the Kuratowski subdivison; if it isn't, see which bridge connects to the Kuratowski subdivision with this edge
             for C in range(len(CC)): # iterate through bridges
                if Legs[L][0] in CC[C][0]:
                    if not Legs[L][1] in CC[C][1]:
                        CC[C][1].append(Legs[L][1]) # mark this vertex as a foot of the bridge
                    CC[C][0].add_edge(Legs[L])
                    SingleEdgeBridges.delete_edge(Legs[L])
                    break # only one bridge can connect to the Kuratowski subdivision using a particular edge
        else:
            if not Legs[L][1] in K: # if the first vertex incident to this edge was in the Kuratowski subdivision, check if the second vertex is; if not, see which bridge connects to the Kuratowski subdivision with this edge
                for C in range(len(CC)): #iterate through bridges
                    if Legs[L][1] in CC[C][0]:
                        if not Legs[L][0] in CC[C][1]:
                            CC[C][1].append(Legs[L][0]) # mark this vertex as a foot of the bridge
                        CC[C][0].add_edge(Legs[L]) # this edge should be in the bridge; one of its vertices is a foot
                        SingleEdgeBridges.delete_edge(Legs[L])
                        break # only one bridge can connect to the Kuratowski subdivision using this edge
    for B in SingleEdgeBridges.edges():
        SEB=graphs.EmptyGraph()
        SEB.add_edge(B)
        CC.append([SEB,SEB.vertices()])
    return CC # a list of pairs whose first entry is a bridge and second entry the feet of that bridge - we want to compare the second entry of each list member to faces of a Kuratowski embedding
︡25730267-bc2b-40af-bb26-03b0cf3ddb31︡{"done":true}
︠cbbb9caf-f0cd-4a9f-9fda-1a3e99433f82undefnedasw︠
%auto
def FaceAssign(bridges,faces):
    BB=deepcopy(bridges)
    for b in range(len(bridges)): # if all the feet of a bridge lie on a single face, test planarity of the bridge attached to the face
        BB[b].append([])
        for f in range(len(faces)):
            if Set(bridges[b][1]).issubset(Set(faces[f].vertices())):
                Emb=bridges[b][0].copy()
                Emb.add_edges(faces[f].edges())
                if Emb.is_planar():
                    BB[b][2].append(f) # record the face in which this bridge embeds
        if BB[b][2]==[]:
            return 0 # if this bridge does not embed in any face, this projective embedding of the Kuratowski minor does not lead to a projective embedding of the entire graph
    return BB
︡62129ba5-43ba-4eec-a9fa-54f473b2e477︡{"done":true}
︠e5ee6694-d757-40f5-a0bf-74f63ffd67edundefnedasw︠
%auto
def FSM(bridge1,bridge2,face):
    state=0
    order=face.hamiltonian_cycle(algorithm='backtrack')[1]
    ### the line above should keep the order of the vertices in the fact, since the face is just a cycle ###
    for v in range(len(order)):
        if state==0:
            if order[v] in bridge1[1]:
                if order[v] in bridge2[1]:
                    state=3
                else:
                    state=1
            elif order[v] in bridge2[1]:
                state=2
        elif state==1:
            if order[v] in bridge2[1]:
                state=5
        elif state==2:
            if order[v] in bridge1[1]:
                state=6
        elif state==3:
            if order [v] in bridge1[1]:
                if order[v] in bridge2[1]:
                    state=4
                else:
                    state=6
            elif order [v] in bridge2[1]:
                state=5
        elif state==4:
            if order[v] in bridge1[1]:
                if order[v] in bridge2[1]:
                    state=9
                else:
                    state=7
            elif order[v] in bridge2[1]:
                state=8
        elif state==5:
            if order[v] in bridge1[1]:
                state=7
        elif state==6:
            if order[v] in bridge2[1]:
                state=8
        elif state==7:
            if order[v] in bridge2[1]:
                state=9
        elif state==8:
            if order[v] in bridge1[1]:
                state=9
    return state
︡1e0f9e4d-93f5-4dba-a731-df0eb8bb4770︡{"done":true}
︠caa94fd6-cfa3-42ae-8437-f606a2ce6693undefnedasw︠
%auto
def Conflicts(FEmb,faces):
    TwoSAT=DiGraph()
    for f in range(len(FEmb)):
        if len(FEmb[f][2])==3: #This shouldn't happen any more
            return 3
        if len(FEmb[f][2])==0: #this bridge cannot be embedded in any face; move on to the next Kuratowski embedding
            return 0
        if len(FEmb[f][2])==1: # this bridge can only be embedded in one face
            TwoSAT.add_edge((f,FEmb[f][2][0],-1),(f,FEmb[f][2][0],1))
        if len(FEmb[f][2])==2: # Make sure no bridge is marked as being embedded in two different faces
            TwoSAT.add_edges([((f,FEmb[f][2][0],-1),(f,FEmb[f][2][1],1)),((f,FEmb[f][2][1],-1),(f,FEmb[f][2][0],1)),((f,FEmb[f][2][0],1),(f,FEmb[f][2][1],-1)),((f,FEmb[f][2][1],1),(f,FEmb[f][2][0],-1))])
        for a in range(f+1,len(FEmb)):# If a later bridge also embeds in this face and the pair conflicts, add edges to the 2-SAT digraph indicating each excludes the other
            for i in range(len(FEmb[f][2])):
                if FEmb[f][2][i] in FEmb[a][2]:
                    if FSM(FEmb[f],FEmb[a],faces[FEmb[f][2][i]])==9:
                        TwoSAT.add_edges([((f,FEmb[f][2][i],1),(a,FEmb[f][2][i],-1)),((a,FEmb[f][2][i],1),(f,FEmb[f][2][i],-1))])


    for f in range(len(FEmb)):
        for i in range(len(FEmb[f][2])):
            if (f,FEmb[f][2][i],-1) in TwoSAT.strongly_connected_component_containing_vertex((f,FEmb[f][2][i],1)):
                return 0
    #print "TwoSAT"
    #TwoSAT.show()
    DAG=TwoSAT.strongly_connected_components_digraph()
    TopS=DAG.topological_sort()
    #print "TopS"
    #print TopS
    SATEm={} # This dictionary sets the value of bridge-face assignments to 1 or -1 depending whether the bridge should be assigned to a particular face. Since it is a result of 2-SAT, each bridge will have a unique face assignment.
    for i in TopS:
        for j in range(len(i)):
            if not (i[j][0],i[j][1]) in SATEm:
                SATEm[(i[j][0],i[j][1])]=-i[j][2]
    #print "SATEm"
    #print SATEm
    BridgeFaces=[]
    for S in SATEm:
        if SATEm[S]==1:
            BridgeFaces.append(S)
    return BridgeFaces
    ###If this does not return 0, need to use this information to identify a solution to the 2-SAT problem and list the bridges embedded in each face so we can print a rotation system###
    
    ####
    #for f in faces:
        #f.show()
    ####
︡ea98e726-e529-43bc-b618-6ff95b2cf896︡{"done":true}
︠68f5e41f-0cd1-43f6-844a-5cd67fd209f1sw︠
%auto
def K5switchnew(H,Kur):
    H.allow_multiple_edges(False)
    b='None'
    for v in Kur:
        if Kur.degree(v)==2:
            b=v
            break
    K33edge=[]
    nbredges=[[],[],[],[]]
    hold=[]
    if b=='None': ###in this case the Kuratowski subgraph is isomorphic to K5###
        for v in H:
            if not v in Kur:
                b=v
                blue=[v]
                break
        red=[]
        PS=H.disjoint_routed_paths([(b,Kur.vertices()[i]) for i in range(3)])
        for i in range(3):
            path=PS[i].shortest_path(b,Kur.vertices()[i])
            for j in range(len(path)):
                if not path[j] in Kur:
                    K33edge.append((path[j],path[j+1]))
                else:
                    red.append(path[j])
                    break
        for v in Kur:
            if v not in blue:
                if v not in red:
                    blue.append(v)
        G=copy(Kur)
        for i in [1,2]:
            for v in G[blue[i]]:
                hold.append((blue[i],v))
                u=v
                G.delete_edge(blue[i],u)
                while Kur.degree(u)<4:
                    w=G[u][0]
                    hold.append((u,w))
                    G.delete_edge(u,w)
                    u=w
                if u in red:
                    K33edge=K33edge+hold
                hold=[]
        T=graphs.EmptyGraph()
        T.add_edges(K33edge)
        return T
    else: ###here the Kuratowski subgraph is a subdivision of K5, and this case is throwing exceptions###
        G=copy(Kur)
        v=b
        for i in range(2):
            u=Kur[b][i]
            K33edge.append((u,b))
            G.delete_edge(u,b)
            nbredges[0].append(u)
            while Kur.degree(u)<4:
                f=G.edges_incident(u)[0]
                v=G[u][0]
                K33edge.append((u,v))
                G.delete_edge(f)
                u=v
                nbredges[0].append(u)
            nbredges[0].remove(u)
            nbredges[1].append(u)
        red=copy(nbredges[1])
        J=copy(H)
        J.delete_vertices(red)
        for v in Kur:
            if v in J and v!=b and v not in nbredges[0]:
                if J.degree(v)>0:
                    path=J.shortest_path(b,v)
                    break
        for v in path:
            if v in nbredges[0]:
                b=v
        for i in range(len(path)):
            if path[i]==b:
                p=path[i:]
                break
        if len(p)>1:
            for i in range(1,len(p)):
                if p[i] in Kur:
                    path=p[:i+1]
                    break
        blue=[b]
        r=path[-1]
        red.append(r)
        for i in range(len(path)-1):
            K33edge.append((path[i],path[i+1]))
        if Kur.degree(r)==4:
            for v in Kur:
                if Kur.degree(v)==4:
                    if v not in blue:
                        if v not in red:
                            blue.append(v)
            hold=[]
            for i in [1,2]:
                for e in G.edges_incident(blue[i]):
                #for e in Kur.edges_incident(blue[i]):
                    if e[0]==blue[i]:
                        u=e[1]
                    else:
                        u=e[0]
                    hold.append((e[0],e[1]))
                    G.delete_edge(e)
                    while Kur.degree(u)<4:
                        e=G.edges_incident(u)[0]
                        v=G[u][0]
                        hold.append((e[0],e[1]))
                        u=v
                    if u in red:
                        K33edge=K33edge+hold
                    hold=[]
        else:
            hold=[]
            maybe=[]
            for i in range(2):
                u=Kur[r][i]
                hold.append((r,u))
                G.delete_edge(r,u)
                while Kur.degree(u)<4:
                    f=G.edges_incident(u)[0]
                    v=G[u][0]
                    hold.append((u,v))
                    G.delete_edge(f)
                    u=v
                if u in nbredges[1]:
                    case=2
                else:
                    maybe.append(u)
                    K33edge=K33edge+hold
                hold=[]
            if case==2:
                red.append(maybe[0])
                for v in Kur:
                    if Kur.degree(v)==4:
                        if v not in blue:
                            if v not in red:
                                blue.append(v)
                for i in [1,2]:
                    for e in G.edges_incident(blue[i]):
                        if e[0]==blue[i]:
                            u=e[1]
                        else:
                            u=e[0]
                        hold.append((blue[i],u))
                        G.delete_edge(e)
                        while Kur.degree(u)<4:
                            e=G.edges_incident(u)[0]
                            v=G[u][0]
                            hold.append((u,v))
                            u=v
                        if u in red:
                            K33edge=K33edge+hold
                        hold=[]
            else:
                red.append(r)
                blue=blue+maybe
                for i in [1,2]:
                    for e in Kur.edges_incident(blue[i]):
                        if e[0]==blue[i]:
                            u=e[1]
                        else:
                            u=e[0]
                        hold.append((blue[i],u))
                        G.delete_edge(e)
                        while Kur.degree(u)<4:
                            e=G.edges_incident(u)[0]
                            v=G[u][0]
                            hold.append((u,v))
                            u=v
                        if u in red:
                            K33edge=K33edge+hold
                        hold=[]
        T=graphs.EmptyGraph()
        T.add_edges(K33edge)
        return T
︡0a72feb2-c662-4c18-a045-471322c8a38f︡{"done":true}
︠c5d51fdf-9c43-4e37-9d5f-936eb399e2e9undefnedasw︠
%auto
Crit=[]
E19=Graph({0:[1,2,3,8], 1:[2,3,8], 2:[3,6],3:[4],4:[5,7],5:[6,8],6:[7],7:[8]});Crit.append(E19);###
E20=Graph({0:[1,2,3,8], 1:[2,3,5], 2:[3,6],3:[4],4:[5,7],5:[6,8],6:[7],7:[8]});Crit.append(E20);###
E22=Graph({0:[1,4,5,8],1:[2,3,7],2:[4,8],3:[4,5],4:[6],5:[6,7],6:[8],7:[8]});Crit.append(E22);###
F1=Graph({0:[2,3,4],1:[2,3,4],2:[5,7],3:[5],4:[6,8],5:[6,8],6:[7],7:[8]});Crit.append(F1);###
B3=Graph({0:[1,2,3,5],1:[2,3,5],2:[3,4,6,7],3:[5],4:[5,6,7],5:[6,7],6:[7]});Crit.append(B3);###
C7=Graph({0:[1,2,3,6],1:[2,3,5,7],2:[3,6],3:[4],4:[5,6,7],5:[6,7],6:[7]});Crit.append(C7);###
D17=Graph({0:[1,2,3,7],1:[2,3,5],2:[3,6],3:[4],4:[5,6,7],5:[6,7],6:[7]});Crit.append(D17);###
K35=Graph({0:[3,4,5,6,7],1:[3,4,5,6,7],2:[3,4,5,6,7]});Crit.append(K35);###
E18=Graph({0:[1,2,3],4:[1,2,3,7],5:[1,2,3,7],6:[1,2,3,7]});Crit.append(E18);###
B1=Graph({0:[1,2,3,4],1:[2,3,4],2:[3,4,5,6],3:[4,5,6],4:[5,6],5:[6]});Crit.append(B1);###
D3=Graph({0:[1,2,3,4],1:[2,3,4],2:[3,5,7],3:[4,6],4:[5,7],5:[6],6:[7]});Crit.append(D3);###
A2=Graph({0:[1,2,3,5,6],1:[2,3,4,5],2:[4,5,6],3:[4,5,6],4:[5,6],5:[6]});Crit.append(A2);###K1,2,2,2
B7=Graph({0:[1,2,3,4,5],1:[2,3,6],2:[3,5,7],3:[4,5,7],4:[5,6],5:[7],6:[7]});Crit.append(B7);### Has a 3-face bridge
E42=Graph({0:[3,4,5],1:[3,4,5],2:[3,4,5],6:[9,10,11],7:[9,10,11],8:[9,10,11]});Crit.append(E42);###K3,3+K3,3
C11=Graph({0:[1,2,3,4],1:[2,3,4],2:[3,4],3:[4],5:[8,9,10],6:[8,9,10],7:[8,9,10]});Crit.append(C11);###K5+K3,3
A5=Graph({0:[1,2,3,4],1:[2,3,4],2:[3,4],3:[4],5:[6,7,8,9],6:[7,8,9],7:[8,9],8:[9]});Crit.append(A5);###K5+K5
E1=Graph({0:[3,4,5],1:[3,4,5],2:[3,4,5],8:[5,6,7],9:[5,6,7],10:[5,6,7]});Crit.append(E1);###K33*K33
C1=Graph({0:[1,2,3,4],1:[2,3,4],2:[3,4],3:[4],7:[4,5,6],8:[4,5,6],9:[4,5,6]});Crit.append(C1);###K5*K3,3
A1=Graph({0:[1,2,3,4],1:[2,3,4],2:[3,4],3:[4],5:[4,6,7,8],6:[4,7,8],7:[4,8],8:[4]});Crit.append(A1);###K5*K5
C2=Graph({0:[1,2,3,5],1:[2,3,5],2:[3,4,6,8],3:[5],4:[5,7],5:[6,8],6:[7],7:[8]});Crit.append(C2);###
D1=Graph({0:[1,3,8],1:[2,4,5,7,9],2:[3,8],3:[4],4:[8],5:[6,8],6:[7,9],7:[8],8:[9]});Crit.append(D1);###
D4=Graph({0:[1,2,3,6,8],1:[2,3,4],2:[3,4],3:[4],4:[5,7],5:[6,8],6:[7],7:[8]});Crit.append(D4);###
D9=Graph({0:[2,3,4],1:[2,3,4],2:[5,6,9],3:[5,6,7],4:[7,9],5:[8],6:[8],7:[8],8:[9]});Crit.append(D9);###
D12=Graph({0:[2,3,4],1:[2,3,4],2:[5,7],3:[5,6],4:[6,7,8],5:[8],6:[7,8],7:[8]});Crit.append(D12);###
E6=Graph({0:[1,3,5],1:[2,4,7,9],2:[3,5],3:[4],4:[5],5:[6,8],6:[7,9],7:[8],8:[9]});Crit.append(E6);###
NewE11=Graph({0:[1,3,9],1:[0,2,4,6,7],2:[3,8],3:[4],4:[5],5:[6,7,8],6:[9],7:[9],8:[9]});Crit.append(NewE11);###
#E11=Graph({0:[2,3,4],1:[2,3,4],2:[5],3:[5,6,7],4:[6,7,8],5:[8],6:[9],7:[9],8:[9]});Crit.append(E11);###
E27=Graph({0:[2,3,4],1:[2,3,4],2:[5,6],3:[5,7],4:[8,9],5:[8],6:[8,9],7:[8,9]});Crit.append(E27);###
F4=Graph({0:[1,3,8],1:[2,4,9],2:[3,7],3:[4],4:[5],5:[6,8],6:[7,9],7:[8],8:[9]});Crit.append(F4);###
F6=Graph({0:[1,3,7,9],1:[2,4],2:[5,3],3:[4],4:[5],5:[6,8],6:[7,9],7:[8],8:[9]});Crit.append(F6);###
G1=Graph({0:[2,3,4],1:[2,3,4],2:[5],3:[6],4:[7],8:[5,6,7],9:[5,6,7]});Crit.append(G1);###
#E5=Graph({0:[2,3,4],1:[2,3,4],2:[5,6,7],3:[5,6,7],4:[5,6,7],8:[5,6,7]});Crit.append(E5);###
NewE5=Graph({0:[1,3,7],1:[2,4,6,8],2:[3,7],3:[4],4:[5,7],5:[6,8],6:[7],7:[8]});Crit.append(NewE5);###
C3=Graph({0:[1,2,3,4,5],1:[2,3,6],2:[3,7],3:[4,5,8],4:[5,6],5:[7],6:[8],7:[8]});Crit.append(C3);###
C4=Graph({0:[1,2,4,5],1:[3,6],2:[3,4,7],3:[4,8],4:[5,6,8],5:[6,7],6:[8],7:[8]});Crit.append(C4);###
D2=Graph({0:[1,2,3,9],1:[2,3,5],2:[3,7],3:[4,8,6],4:[5,9],5:[6],6:[7],7:[8],8:[9]});Crit.append(D2);### Has a 3-face bridge
E2=Graph({0:[1,5,7],2:[1,3,8],4:[3,5,9],6:[7,8,9],10:[1,3,5,7,8,9]});Crit.append(E2)### 
︡f81bc06c-9ad7-4b97-8b3d-e4a6778a0b1b︡{"done":true}
︠865363a9-49d0-4d99-88dd-285e45aca1c0undefnedasw︠
%auto
def cross(G,e,f):
    # This function crosses the edges e and f in the graph G, that is,
    # it deletes e and f, and adds a new vertex v adjacent to all vertices incident with e and f.
    G.delete_edge(e)
    G.delete_edge(f)
    # The loop below finds the first number available as the name of the new vertex v.
    for v in range(G.order()+1):
        if not (G.has_vertex(v)):
            break
    G.add_vertex(name=v)
    G.add_edge(v,e[0])
    G.add_edge(v,e[1])
    G.add_edge(v,f[0])
    G.add_edge(v,f[1])
︡9e4cf285-67fa-4ddb-ab53-eca4fe11784e︡{"done":true}
︠084210c6-707c-435e-adc9-01defc9c9d31undefnedasw︠
%auto
def line_graph(G):
    L=graphs.EmptyGraph()
    H=graphs.EmptyGraph()
    H.allow_multiple_edges(True)
    i=0
    for e in G.edge_iterator(labels=True):
        if e in G.multiple_edges():
            H.add_edge(e[0],e[1],i)
            L.add_vertex((e[0],e[1],i))
        else:
            H.add_edge(e[0],e[1])
            L.add_vertex((e[0],e[1],None))
        i=i+1
    for v in  H.vertex_iterator():
        for f in H.edge_iterator(v,labels=True):
            for g in H.edge_iterator(v,labels=True):
                L.add_edge(f,g)
    return H,L
︡9c82fb59-4080-4702-b785-8451770bed0c︡{"done":true}
︠10873a85-bafa-4a35-8417-6761d0938608sw︠
%auto
def is_ppx2(G):
    #This function returns True if G requires at least two crossings when drawn in the projective plane.
    if is_projective(G,0)==1:
        return False
    lab_G,line_G=line_graph(G)
    aut=line_G.automorphism_group(return_group=False, orbits=True)
    aut.sort()
    for orb in range(len(aut)):
        aut[orb].sort()
        e=aut[orb][0]
        if e not in G.multiple_edges(labels=True):
            rest=lab_G.edges(labels=True,sort=True)
            rest.remove(e)
            part=[[e],rest]
            aut2=line_G.automorphism_group(return_group=False, orbits=True, partition=part)
            aut2.remove([e])
            aut2.sort()
            for orb2 in range(len(aut2)):
                f=aut2[orb2][0]
                if f not in G.multiple_edges(labels=True) and e[0]!=f[0] and e[1]!=f[0] and e[1]!=f[1] and e[0]!=f[1]:
                    G_x=copy(G)
                    cross(G_x,e,f)
                    G_x.relabel()
                    if is_projective(G_x,0)==1:
                        G_x.clear()
                        return False
                    G_x.clear()
    return True
︡76ca46b6-81e0-47a2-9027-3c1b0fffbdcd︡{"done":true}
︠fdcd8fcb-9e76-4b19-8aea-1e968e0cc5cbsw︠
%auto
def edge_orbit_reps(G):
    L=G.line_graph()
    O=L.automorphism_group(orbits=True)[1]
    return [O[i][0] for i in range(len(O))]
︡98c4fc0b-b971-4e2d-836a-61b0c6cf2d44︡{"done":true}
︠d568f354-7114-4095-84b2-6ae23635c0b1s︠
for i in range(len(Crit)):
    if Crit[i].is_connected():
        for e in edge_orbit_reps(Crit[i]):
            H=copy(Crit[i])
            #H.merge_vertices([e[0],e[1]])
            H.delete_edge(e)
            print i,e
            is_projective(H)
︡eb6a5ca8-05c4-4c85-af66-2dccc8577740︡
︠7b803f6f-4f38-4f5f-98ef-e81213eb3a7fs︠
%timeit
is_projective(Crit[0])
︡8cbc7c3e-22a9-4978-8594-aa72043d4bc4︡{"stdout":"5 loops, best of 3: 229 ms per loop"}︡{"stdout":"\n"}︡{"done":true}︡
︠6ac531ef-5cb8-43e4-859f-8a96ec009be4s︠
F2=Graph({0:[1,12],1:[2,13,14],2:[3,15],3:[4,15],4:[5,16,17],5:[6,18],6:[7,18],7:[8,19,20],8:[9,21],9:[10,21],10:[11,22,23],11:[0,12],13:[12,14],15:[14,16],17:[16,18],19:[18,20],21:[20,22],23:[22,0],24:[2,5,8,13,16,22]})
︡7ff00421-9cbc-4993-bdfa-1524d3f7fc48︡{"done":true}︡
︠0334500b-aeae-4c65-9428-11e0e28fc2d7s︠
is_projective(F2)
︡b117891a-67b9-4adb-9776-4608cb11e7cf︡{"stdout":"1"}︡{"stdout":"\n"}︡{"done":true}︡
︠c6a86965-9f4a-48d2-aa21-745e48f173cc︠
F2.minor(F1)
︡85c6c66f-ae79-47ad-bd0e-f0b26c84290e︡
︠6659d238-0ab6-4ad5-b623-88cf5050cda3︠
F2.is_planar()
︡85e8cb02-120f-4a3a-a1e4-23e6f8169942︡
︠143a3625-48b9-4660-8903-7751502855df︠









