import numpy as np

from hyperliquid_observation_builder import (
    OBS_DTYPE,
    OBSERVATION_DIM,
    HyperliquidObservationBuilder,
)


def test_smoke_builder_basics() -> None:
    builder = HyperliquidObservationBuilder()
    obs = builder.build_observation()
    labels = builder.get_observation_labels()

    assert obs.shape == (OBSERVATION_DIM,)
    assert obs.dtype == OBS_DTYPE
    assert obs.dtype == np.float32
    assert len(labels) == OBSERVATION_DIM
    assert builder.get_obs_quality_flags().shape == (4,)
    assert builder._build_category1().shape == (42,)
    assert builder._build_category2().shape == (21,)
    assert builder._build_category3().shape == (31,)
    assert builder._build_category4().shape == (11,)
