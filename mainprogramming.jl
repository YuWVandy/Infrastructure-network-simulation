using Juniper
using JuMP
using Ipopt
using Cbc
using DelimitedFiles
using LatinHypercubeSampling

include("python2juliadata.jl")

#Define the network nodes
gnum, gdemandnum, gtransnum, gsupplynum = Gasdict["nodenum"], Gasdict["demandnum"], Gasdict["trannum"], Gasdict["supplynum"]
pnum, pdemandnum, ptransnum, psupplynum = Powerdict["nodenum"], Powerdict["demandnum"], Powerdict["trannum"], Powerdict["supplynum"]
wnum, wdemandnum, wtransnum, wsupplynum = Waterdict["nodenum"], Waterdict["demandnum"], Waterdict["trannum"], Waterdict["supplynum"]

#Define transformation mapping: list2adj and adj2list
Gadj2list, Glist2adj = sf.list_adj(Gasadj)
Padj2list, Plist2adj = sf.list_adj(Poweradj)
Wadj2list, Wlist2adj = sf.list_adj(Wateradj)

GPadj2list, GPlist2adj = sf.list_adj(gdemand2psupplyadj)
PGadj2list, PGlist2adj = sf.list_adj(pdemand2glinkadj)
PWadj2list, PWlist2adj = sf.list_adj(pdemand2wlinkadj)
WPadj2list, WPlist2adj = sf.list_adj(wdemand2psupplyadj)

PWinterlinkadj2list, PWinterlinkadjlist2adj = sf.list_adj(pdemand2wpinterlinkadj)
PGinterlinkadj2list, PGinterlinklist2adj = sf.list_adj(pdemand2gpinterlinkadj)

season_name = ["spring", "summer", "autumn", "winter"]
for sea in 1:length(dt.powervar)
    powerseason = dt.powervar[sea]
    for mm in 1:length(powerseason)
        powerperunit = 1*powerseason[mm] #the coefficient is about the data we get is from the summer
        #Initialization using latinhypercube sampling
        flag = 0
        optimal_value = Inf16
        while(flag == 0)
            initial_point = LHCoptim(1000, 7, 1000)[1]
            scaled_initial_point = scaleLHC(initial_point, [(1, 1000), (1, 1000), (1, 1000), (1, 1000), (1, 1000), (1, 1000), (1, 1000)])

            for nn in 1:size(scaled_initial_point)[1]
                #Model set up
                # optimizer = Juniper.Optimizer
                # nl_solver = optimizer_with_attributes(Ipopt.Optimizer, "print_level" =>0)
                # mp = Model(with_optimizer(Ipopt.Optimizer, print_level = 0, max_iter = 10000, "nl_solver"=>nl_solver))

                optimizer = Juniper.Optimizer
                nl_solver = optimizer_with_attributes(Ipopt.Optimizer, "print_level" =>0)
                mip_solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 0)
                mp = Model(optimizer_with_attributes(optimizer, "nl_solver"=>nl_solver, "mip_solver"=>mip_solver))
    #
                # mp = Model(optimizer_with_attributes(Ipopt.Optimizer,  "max_iter" => 5000))

                #------------------------------------------------Define the programming variables
                #network
                @variable(mp,  Gflow[1:size(Glist2adj)[1]] >= 0, start = scaled_initial_point[nn,1]) #m^3/s
                @variable(mp, Pload[1:pnum] >= 0, start = scaled_initial_point[nn,2]) #kw.h/s
                @variable(mp, 1.1356 >= Wflow[1:size(Wlist2adj)[1]] >= 0.00001, start = scaled_initial_point[nn,3]) #m^3/s
                @variable(mp, Gpr[1:gnum] >= 0.00001, start = scaled_initial_point[nn,4])
                @variable(mp, Ppr[1:psupplynum] >= 0.00001, start = scaled_initial_point[nn,5])
                #between network
                @variable(mp, GPflow[1:size(GPlist2adj)[1]] >= 0, start = scaled_initial_point[nn,6])
                # @variable(mp, PGload[1:size(PGlist2adj)[1]] >= 0)
                # @variable(mp, PWload[1:size(PWlist2adj)[1]] >= 0)
                @variable(mp, WPflow[1:size(WPlist2adj)[1]] >= 0.00001, start = scaled_initial_point[nn,7])
                #
                # @variable(mp,  Gflow[1:size(Glist2adj)[1]] >= 0) #m^3/s
                # Gflowvalue = Matrix(CSV.read("./optimized_result/Gflow0.csv", datarow = 1))
                # for i in 1:length(Gflowvalue)
                #     set_start_value(Gflow[i], Gflowvalue[i])
                # end
                # @variable(mp, Pload[1:pnum] >= 0) #kw.h/s
                # Ploadvalue = Matrix(CSV.read("./optimized_result/Pload0.csv", datarow = 1))
                # for i in 1:length(Ploadvalue)
                #     set_start_value(Pload[i], Ploadvalue[i])
                # end
                # @variable(mp, Wflow[1:size(Wlist2adj)[1]] >= 0.00001) #m^3/s
                # Wflowvalue = Matrix(CSV.read("./optimized_result/Wflow0.csv", datarow = 1))
                # for i in 1:length(Wflowvalue)
                #     set_start_value(Wflow[i], Wflowvalue[i])
                # end
                # @variable(mp, Gpr[1:gnum] >= 0.00001)
                # Gprvalue = Matrix(CSV.read("./optimized_result/Gpr0.csv", datarow = 1))
                # for i in 1:length(Gprvalue)
                #     set_start_value(Gpr[i], Gprvalue[i])
                # end
                # @variable(mp, Ppr[1:psupplynum] >= 0.00001)
                # Pprvalue = Matrix(CSV.read("./optimized_result/Ppr0.csv", datarow = 1))
                # for i in 1:length(Pprvalue)
                #     set_start_value(Ppr[i], Pprvalue[i])
                # end
                # #between network
                # @variable(mp, GPflow[1:size(GPlist2adj)[1]] >= 0.00001)
                # GPflowvalue = Matrix(CSV.read("./optimized_result/GPflow0.csv", datarow = 1))
                # for i in 1:length(GPflowvalue)
                #     set_start_value(GPflow[i], GPflowvalue[i])
                # end
                # # @variable(mp, PGload[1:size(PGlist2adj)[1]] >= 0)
                # # @variable(mp, PWload[1:size(PWlist2adj)[1]] >= 0)
                # @variable(mp, WPflow[1:size(WPlist2adj)[1]] >= 0.00001)
                # WPflowvalue = Matrix(CSV.read("./optimized_result/WPflow0.csv", datarow = 1))
                # for i in 1:length(WPflowvalue)
                #     set_start_value(WPflow[i], WPflowvalue[i])
                # end

                # @variable(mp,  Gflow[1:size(Glist2adj)[1]] >= 0, start = 100) #m^3/s
                # @variable(mp, Pload[1:pnum] >= 0, start = 500) #kw.h/s
                # @variable(mp, Wflow[1:size(Wlist2adj)[1]] >= 0.00001, start = 50) #m^3/s
                # @variable(mp, Gpr[1:gnum] >= 0.00001, start = 500)
                # @variable(mp, Ppr[1:psupplynum] >= 0.00001, start = 500)
                # #between network
                # @variable(mp, GPflow[1:size(GPlist2adj)[1]] >= 0.00001, start = 500)
                # # @variable(mp, PGload[1:size(PGlist2adj)[1]] >= 0)
                # # @variable(mp, PWload[1:size(PWlist2adj)[1]] >= 0)
                # @variable(mp, WPflow[1:size(WPlist2adj)[1]] >= 0.00001, start = 500)


                #------------------------------------------------Constraints
                ###------------------flow conservation
                #for transmission nodes in water networks
                Wtflowin, Wtflowout = sf.tranflowinout(Waterdict, Wflow, Wateradj, Wadj2list)
                @constraint(mp, Wtconserve[i = 1:wtransnum], sum(Wtflowin[i]) == sum(Wtflowout[i]))

                #for transmission nodes in gas networks
                Gtflowin, Gtflowout = sf.tranflowinout(Gasdict, Gflow, Gasadj, Gadj2list)
                @constraint(mp, Gtconserve[i = 1:gtransnum], sum(Gtflowin[i]) == sum(Gtflowout[i]))

                #for demand nodes in water networks
                #flow in and out within demand nodes in the water networks
                Wdflowin, Wdflowout1 = sf.demandflowinout(Waterdict, Wflow, Wateradj, Wadj2list)
                #flow: water demand -> power supply
                Wdflowout2 = sf.demandinterflowout(wdemand2psupplyadj, Waterdict, Powerdict, WPflow, WPadj2list)
                #flow: water demand -> residents
                Wdflowout3 = dt.waterperunit*Waterdict["population_assignment"]
                @constraint(mp, Wdconserve[i = 1:wdemandnum], sum(Wdflowin[i]) == sum(Wdflowout1[i]) + sum(Wdflowout2[i]) + sum(Wdflowout3[i]))

                #for demand nodes in gas networks
                #flow in and out within demand nodes in the gas networks
                Gdflowin, Gdflowout1 = sf.demandflowinout(Gasdict, Gflow, Gasadj, Gadj2list)
                #flow: gas demand -> power supply
                Gdflowout2 = sf.demandinterflowout(gdemand2psupplyadj, Gasdict, Powerdict, GPflow, GPadj2list)
                #flow: Gas demand -> residents
                Gdflowout3 = dt.gasperunit*Gasdict["population_assignment"]
                @constraint(mp, Gdconserve[i = 1:gdemandnum], sum(Gdflowin[i]) == sum(Gdflowout1[i]) + sum(Gdflowout2[i]) + sum(Gdflowout3[i]))

                #for demand and supply nodes in power networks
                #power load of demand nodes equal to the power load of supply nodes
                @constraint(mp, Pdsconserve, sum(Pload[Powerdict["supplyseries"][i]] for i in 1:psupplynum) == sum(Pload[Powerdict["demandseries"][i]] for i in 1:pdemandnum))

                ###------------------dependency of power supply nodes on gas demand nodes
                GdflowinPs = sf.supplyinterflowin(gdemand2psupplyadj, Gasdict, Powerdict, GPflow, GPadj2list)
                @NLconstraint(mp, GdPsinter[i = 1:psupplynum], sum(GdflowinPs[i][j] for j in 1:length(GdflowinPs[i])) == (dt.au + dt.bu*Pload[i] + dt.cu*Pload[i]^2)/(dt.H)*3600)

                ###------------------dependency of power supply nodes on water demand nodes
                WdflowinPs = sf.supplyinterflowin(wdemand2psupplyadj, Waterdict, Powerdict, WPflow, WPadj2list)
                @constraint(mp, WdPsinter[i = 1:psupplynum], sum(WdflowinPs[i]) == dt.kapa*Pload[i])

                ###------------------dependency of water links on power demand nodes
                #water links in water networks
                PdWlflowout1, H1_1, H2_1, L_1 = sf.pdemandwlinkflowout(pdemand2wlinkadj, Wflow, Waterdict, pdemand2wlinklink2nodeid, Waterdistnode2node)
                #water links from water demand nodes to power supply nodes
                PdWlflowout2, H1_2, H2_2, L_2 = sf.pdemandwpinterlinkflowout(pdemand2wpinterlinkadj, WPflow, Waterdict, Powerdict, pdemand2wpinterlinklink2nodeid, wdemand2psupplydistnode2node)

                PdWlflowout1, H1_1, H2_1, L_1 = sf.zeropad(PdWlflowout1), sf.zeropad(H1_1), sf.zeropad(H2_1), sf.zeropad(L_1)
                PdWlflowout2, H1_2, H2_2, L_2 = sf.zeropad(PdWlflowout2), sf.zeropad(H1_2), sf.zeropad(H2_2), sf.zeropad(L_2)

                ###-----------------dependency of gas links on power demand nodes
                #gas links in gas networks
                PdGlflowout1, Pr1_1, Pr2_1 = sf.pdemandglinkflowout(pdemand2glinkadj, Gflow, Gpr, pdemand2glinklink2nodeid)
                # PdGlflowout1, Pr1_1, Pr2_1 = sf.zeropad(PdGlflowout1), sf.zeropad(Pr1_1), sf.zeropad(Pr2_1)
                #gas links from gas demand nodes to power supply nodes
                PdGlflowout2, Pr1_2, Pr2_2 = sf.pdemandgpinterlinkflowout(pdemand2gpinterlinkadj, GPflow, Gpr, Ppr, Gasdict, Powerdict, pdemand2gpinterlinklink2nodeid)
                # PdGlflowout2, Pr1_2, Pr2_2 = sf.zeropad(PdGlflowout2), sf.zeropad(Pr1_2), sf.zeropad(Pr2_2)


                @NLconstraint(mp, Pdwglink[i = 1:pdemandnum], 2.7e-7*sum(dt.wdensity*dt.g*PdWlflowout1[i][j]*(H2_1[i][j] - H1_1[i][j]) for j in 1:length(H2_1[i])) +
                            2.7e-7*sum(10.654*(PdWlflowout1[i][j]/dt.beta)^1.852*(L_1[i][j]*1000/Waterdict["edgediameter"]^4.87) for j in 1:length(H2_1[i])) +
                            2.7e-7*sum(dt.wdensity*dt.g*PdWlflowout2[i][j]*(H2_2[i][j] - H1_2[i][j]) for j in 1:length(H2_2[i])) +
                            2.7e-7*sum(10.654*(PdWlflowout2[i][j]/dt.beta)^1.852*(L_2[i][j]*1000/Waterdict["edgediameter"]^4.87) for j in 1:length(H2_2[i])) +
                            sum(79.135*((Pr2_1[i][j]/Pr1_1[i][j])^0.2753623 - 1)*PdGlflowout1[i][j]/3600 for j in 1:length(Pr2_1[i])) +
                            sum(79.135*((Pr2_2[i][j]/Pr1_2[i][j])^0.2753623 - 1)*PdGlflowout2[i][j]/3600 for j in 1:length(Pr2_2[i])) +
                            powerperunit*Powerdict["population_assignment"][i] == Pload[Powerdict["demandseries"][i]])

                # pressure and flow constraint in gas networks
                @NLconstraint(mp, Glinkprflow[i = 1:length(Gflow)], Gflow[i]^(1/dt.delta5) == 4.812*(Gpr[Glist2adj[i, 1]]^2 - Gpr[Glist2adj[i, 2]]^2)/(Gasdistnode2node[Glist2adj[i, 1], Glist2adj[i, 2]]))
                # @NLconstraint(mp, Glinkprflow[i = 1:length(Gflow)], (Gflow[i]*127133)^(1/dt.delta5) == (dt.delta1*dt.e*(Gasdict["edgediameter"]*39.3701)^dt.delta2*(dt.Ts/dt.Prs)^dt.delta3)^(1/dt.delta5)*((Gpr[Glist2adj[i, 1]]/100)^2 - (Gpr[Glist2adj[i, 2]]/100)^2)/(dt.xi^dt.delta4*Gasdistnode2node[Glist2adj[i, 1], Glist2adj[i, 2]]*0.621371*(dt.T*9/5 + 491.67)*dt.phi))


                # # # # #pressure and flow constraint in interdependent gas-power networks
                @NLconstraint(mp, G2Plinkprflow[i = 1:(length(GPflow))], GPflow[i]^(1/dt.delta5) == 4.812*(Gpr[Gasdict["demandseries"][GPlist2adj[i, 1]]]^2 - Ppr[Powerdict["supplyseries"][GPlist2adj[i, 2]]]^2)/(gdemand2psupplydistnode2node[GPlist2adj[i, 1], GPlist2adj[i, 2]]))
                # @NLconstraint(mp, G2Plinkprflow[i = 1:length(GPflow)], (GPflow[i]*127133)^(1/dt.delta5) <= (dt.delta1*dt.e*(Gasdict["edgediameter"]*39.3701)^dt.delta2*(dt.Ts/dt.Prs)^dt.delta3)^(1/dt.delta5)*((Gpr[Gasdict["demandseries"][GPlist2adj[i, 1]]]/100)^2 - (Ppr[Powerdict["supplyseries"][GPlist2adj[i, 2]]]/100)^2)/(dt.xi^dt.delta4*gdemand2psupplydistnode2node[GPlist2adj[i, 1], GPlist2adj[i, 2]]*0.621371*(dt.T*9/5 + 491.67)*dt.phi))

                @objective(mp, Min, sum(Wflow[i]*Waterdistnode2node[Wlist2adj[i, 1], Wlist2adj[i, 2]] for i in 1:length(Wflow))*dt.cw +
                                    sum(Gflow[i]*Gasdistnode2node[Glist2adj[i, 1], Glist2adj[i, 2]] for i in 1:length(Gflow))*dt.cg +
                                    sum(Pload[i] for i in Powerdict["supplyseries"])*dt.cp +
                                    sum(WPflow[i]*wdemand2psupplydistnode2node[WPlist2adj[i, 1], WPlist2adj[i, 2]] for i in 1:length(WPflow))*dt.cw +
                                    sum(GPflow[i]*gdemand2psupplydistnode2node[GPlist2adj[i, 1], GPlist2adj[i, 2]] for i in 1:length(GPflow))*dt.cg)

                optimize!(mp)
                # set_start_value.(all_variables(mp), value.(all_variables(mp)))





            #     writedlm("./optimized_result/Pload$(mm-1).csv", value.(Pload), ',')
            #     writedlm("./optimized_result/Wflow$(mm-1).csv", value.(Wflow), ',')
            #     writedlm("./optimized_result/Gflow$(mm-1).csv", value.(Gflow), ',')
            #     writedlm("./optimized_result/GPflow$(mm-1).csv", value.(GPflow), ',')
            #     writedlm("./optimized_result/WPflow$(mm-1).csv", value.(WPflow), ',')
            #     writedlm("./optimized_result/Gpr$(mm-1).csv", value.(Gpr), ',')
            #     writedlm("./optimized_result/Ppr$(mm-1).csv", value.(Ppr), ',')
            # end
                # set_start_value.(all_variables(model), value.(all_variables(model)))
                if(termination_status(mp) == MOI.LOCALLY_SOLVED)
                    flag = 1
                    if(objective_value(mp) < optimal_value)
                        optimal_value = objective_value(mp)
                        writedlm(string("./optimized_result/", season_name[sea], "/Pload$(mm-1).csv"), value.(Pload), ',')
                        writedlm(string("./optimized_result/", season_name[sea], "/Wflow$(mm-1).csv"), value.(Wflow), ',')
                        writedlm(string("./optimized_result/", season_name[sea], "/Gflow$(mm-1).csv"), value.(Gflow), ',')
                        writedlm(string("./optimized_result/", season_name[sea],"/GPflow$(mm-1).csv"), value.(GPflow), ',')
                        writedlm(string("./optimized_result/", season_name[sea],"/WPflow$(mm-1).csv"), value.(WPflow), ',')
                        writedlm(string("./optimized_result/", season_name[sea],"/Gpr$(mm-1).csv"), value.(Gpr), ',')
                        writedlm(string("./optimized_result/", season_name[sea],"/Ppr$(mm-1).csv"), value.(Ppr), ',')
                        print("update the file")
                    end
                end
            end
        end
        print("run the next time point")
        print(mm)
     end
     print("run the next season")
     print(season_name[sea])
end
