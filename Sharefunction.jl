module sf
    function list_adj(adjmatrix)
        #= Construct the adj2list map and list2adj map based on adjmatrix
        Input: adjmatrix - 2D array, the adjacent matrix of a network or a dependent network
        Output: adj2list - 2D array, adj2list[i, j]: the index number of link_{ij} in list
                list2adj - 2D array, list2adj[i, 1], list2adj[i, 2]: the row and column index of link i in the list
        =#
        rownum, columnnum = size(adjmatrix)[1], size(adjmatrix)[2]
        adj2list = Array{Int64}(undef, rownum, columnnum)
        list2adj = Array{Int64}(undef, Int64(sum(adjmatrix)), 2)

        temp = 0
        for i in range(1, rownum)
            for j in range(1, columnnum)
                if(adjmatrix[i, j] == 1)
                    temp += 1

                    adj2list[i, j] = temp
                    list2adj[temp, 1], list2adj[temp, 2] = i, j
                else
                    adj2list[i, j] = 0

                end
            end
        end

        return adj2list, list2adj
    end

    function array2dict(array, index1, index2)
        #= Construct the dictionary of the network information
        Input: array - 2D array of the network information
               index - the index of the network feature which requires number type of structure to save, not string
        Output: dictionary of the network information
        =#
        dict = Dict()
        for i in 1:(size(array)[1])
            if(i >= index1[1] && i <= index1[2])
                if( i >= index2[1] && i <= index2[2])
                    dict[array[i, 1]] = eval(Meta.parse(array[i, 2])).+1 #the difference of the start index between python and julia
                else
                    dict[array[i, 1]] = eval(Meta.parse(array[i, 2]))
                end
            else
                dict[array[i, 1]] = array[i, 2]
            end
        end
        return dict
    end

    function array2dict(array, index1, index2)
        #= Construct the dictionary of the network information
        Input: array - 2D array of the network information
               index - the index of the network feature which requires number type of structure to save, not string
        Output: dictionary of the network information
        =#
        dict = Dict()
        for i in 1:(size(array)[1])
            if(i >= index1[1] && i <= index1[2])
                if( i >= index2[1] && i <= index2[2])
                    dict[array[i, 1]] = eval(Meta.parse(array[i, 2])).+1 #the difference of the start index between python and julia
                else
                    dict[array[i, 1]] = eval(Meta.parse(array[i, 2]))
                end
            else
                dict[array[i, 1]] = array[i, 2]
            end
        end
        return dict
    end

    function tranflowinout(Dict, Flow, Adj, adj2list)
        #= Set up the flow iterms going into and out of the transmission nodes
        Input: Dict - Dictionary of the network information
               Flow - The flow variable set up for the optimization problem
               Adj - 2D array, the adjacent matrix of the network
               adj2list - the map from the adjacent matrix to flow list
        Output: the array of flow going into and out of the certain nodes
        =#
        flowin = []
        flowout = []
        for i in 1:Dict["trannum"]
            trannum = Dict["transeries"][i]

            flowinnode = []
            flowoutnode = []
            for j in 1:Dict["nodenum"]
                if(Adj[j, trannum] == 1)
                    push!(flowinnode, Flow[adj2list[j, trannum]])
                end
                if(Adj[trannum, j] == 1)
                    push!(flowoutnode, Flow[adj2list[trannum, j]])
                end
            end
            push!(flowin, flowinnode)
            push!(flowout, flowoutnode)
        end
        return flowin, flowout
    end
end
