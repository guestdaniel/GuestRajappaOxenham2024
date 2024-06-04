export theme_thesis

const scale_factor = 100
function theme_thesis()
    Theme(
        Axis = (
            backgroundcolor = :transparent,
            xgridvisible = false,
            ygridvisible = false,
            xminorgridvisible = false,
            yminorgridvisible = false,
            leftspinevisible = true,
            rightspinevisible = false,
            bottomspinevisible = true,
            topspinevisible = false,
            xminorticksvisible = true,
            yminorticksvisible = true,
            xticksvisible = true,
            yticksvisible = true,
            xlabelpadding = 3,
            ylabelpadding = 3
        ),
        Legend = (
            framevisible = false,
            padding = (0, 0, 0, 0),
        ),
        Axis3 = (
            xgridvisible = false,
            ygridvisible = false,
            zgridvisible = false,
            xspinesvisible = true,
            yspinesvisible = true,
            zspinesvisible = true,
            yzpanelvisible = false,
            xzpanelvisible = false,
            xypanelvisible = false,
            xticksvisible = false,
            yticksvisible = false,
            zticksvisible = false,
            xticklabelpad = 3,
            yticklabelpad = 3,
            zticklabelpad = 6,
            xspinecolor_2 = :transparent,
            xspinecolor_3 = :transparent,
            yspinecolor_2 = :transparent,
            yspinecolor_3 = :transparent,
            zspinecolor_2 = :transparent,
            zspinecolor_3 = :transparent,
        ),
        Colorbar = (
            ticksvisible = false,
            spinewidth = 0,
            ticklabelpad = 5,
        ),
        Lines = (
            linewidth = 3.0,
        ),
        Scatter = (
            markersize=18.0,
        ),
        Errorbars = (
            linewidth = 3.0,
            whiskerwidth = 12.0,
        )
    )
end

