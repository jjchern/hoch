cap pr drop hoch
pr def hoch

	gettoken main options: 0, p(",") 		
	gettoken cost_eq effect_eq: main, bind 
	
	gettoken cost_eq_lhs cost_eq_rhs: cost_eq
	local cost_eq_lhs = subinstr("`cost_eq_lhs'", "(", "", 1)
	local cost_eq_rhs = subinstr("`cost_eq_rhs'", ")", "", 1)
	
	gettoken effect_eq_lhs effect_eq_rhs: effect_eq
	local effect_eq_lhs = subinstr("`effect_eq_lhs'", "(", "", 1)
	local effect_eq_rhs = subinstr("`effect_eq_rhs'", ")", "", 1)
	
	di "-----------------------------------------------------------------------"
	di "The cost regression:"
	reg `cost_eq_lhs' `cost_eq_rhs', r
	local dc = _b[`cost_eq_rhs']
	local dc2 = `dc' * `dc'
	local se_dc = _se[`cost_eq_rhs']
	di "-----------------------------------------------------------------------"
	di ""
	
	di "The benefit regression:"
	reg `effect_eq_lhs' `effect_eq_rhs', r
	local de = _b[`effect_eq_rhs']
	local de2 = `de' * `de'
	local se_de = _se[`effect_eq_rhs']
	di "-----------------------------------------------------------------------"
	di ""
	
	syntax anything [, ICER FIELLER CEFIG INB LAMBDA(integer 100000)]
	
	if `"`icer'"' != "" & `"`fieller'"' == "" {
		di "So, you asked for the ICER?"
		di "The ICER is " `dc' / `de'
		di "-----------------------------------------------------------------------"
		di ""
	}
	
	if `"`icer'"' != "" & `"`fieller'"' != "" {
		di "So, you asked for the ICER and the Fieller confidence limits for the ICER?"
		
		qui corr `cost_eq_lhs' `effect_eq_lhs' if `cost_eq_rhs' == 0
		local rho_0 = r(rho)
		
		qui corr `cost_eq_lhs' `effect_eq_lhs' if `cost_eq_rhs' == 1
		local rho_1 = r(rho)
		
		qui ttest `cost_eq_lhs', by (`cost_eq_rhs')
		local se_c0 = r(sd_1)
		local se_c1 = r(sd_2)
		local df = r(df_t)
		local n0 = r(N_1)
		local n1 = r(N_2)
		
		qui ttest `effect_eq_lhs', by(`cost_eq_rhs')
		local se_e0 = r(sd_1)
		local se_e1 = r(sd_2)
		
		local cov = (`rho_1' * `se_c1' * `se_e1') / `n1' + (`rho_0' * `se_c0' * `se_e0') / `n0'
		local corr = `cov' / (`se_dc' * `se_de')
		local t = invttail(`df', 0.025)
		
		local MM = `de' * `dc' - `t' ^ 2 * `corr' * `se_de' * `se_dc'
		local NN = `de' ^ 2 - `t' ^ 2 * `se_de' ^ 2
		local OO = `dc' ^ 2 - `t' ^ 2 * `se_dc' ^ 2
		
		local ll = round((`MM' - (`MM' ^ 2 - `NN' * `OO') ^ 0.5) / `NN', .001)
		local ul = round((`MM' + (`MM' ^ 2 - `NN' * `OO') ^ 0.5) / `NN', .001)
		
		di "The ICER is " `dc' / `de'
		di "And the Fieller 95% CI is [`ll', `ul']" 
		
		di "-----------------------------------------------------------------------"
		di ""
	}
	
	if `"`cefig'"' != "" {
		di "Assuming Delta C and Delta E are jointly distributed as a bivarate normal..."
		di "You'd get the confidence ellipse on the cost-effectiveness space (see the figure)."
		
		gen theta = _pi * 2 * (_n - 1) / (`n0' + `n1' - 1)
		gen part1_c95 = sqrt(-2 * log(1 - 0.95)) * `se_dc'
		gen part1_e95 = sqrt(-2 * log(1 - 0.95)) * `se_de'
		
		gen part2_c = cos(theta - acos(`corr') / 2)
		gen part2_e = cos(theta + acos(`corr') / 2)
		
		gen delta_c95 = part1_c95 * part2_c + `dc'
		gen delta_e95 = part1_e95 * part2_e + `de'
		
		gen dc = `dc'
		gen de = `de'
		
		sc delta_c95 delta_e95, yline(0) xline(0) m(i) c(l) || sc dc de, legend(off) msymbol(D) title(The Confidence Ellipse)
		
		di "-----------------------------------------------------------------------"
		di ""
	}
		
	if `"`inb'"' != "" & `"`lambda'"' == "" {
		di "Oh, you're interested in the INB?"
		di "Using a default lambda = 100000, you get:"
		gen nb_100000 = 100000 * `effect_eq_lhs' - `cost_eq_lhs'
		reg nb_100000 `effect_eq_rhs', r
		di "-----------------------------------------------------------------------"
		di ""
	}
	
	if `"`inb'"' != "" & "`lambda'" != "" & {
		di "Oh, you're interested in the INB?"
		di "Using a default lambda = `lambda', you get:"
		gen nb_`lambda' = `lambda' * `effect_eq_lhs' - `cost_eq_lhs'
		reg nb_`lambda' `effect_eq_rhs', r
		di "-----------------------------------------------------------------------"
		di ""
	}
end
