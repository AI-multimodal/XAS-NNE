# XANES ML-ready ACSF database 22 June 2022

**Filenames:** `XANES-220622-ACSF-*.pkl` (and `XANES-220622-ACSF-*-small.pkl` for a small random subset for debugging), where the `*` represents the absorbing atom type.

Processed from `XANES-220622-C-N-O.pkl`. ACSF vectors computed using parameters

```python
from dscribe.descriptors import ACSF
species = ["H", "C", "O", "N", "F"]
rcut = 6.0
g2_params = [[1.0, 0], [0.1, 0], [0.01, 0]]
g4_params = [
    [0.001, 1.0, -1.0],
    [0.001, 2.0, -1.0],
    [0.001, 4.0, -1.0],
    [0.01, 1.0, -1.0],
    [0.01, 2.0, -1.0],
    [0.01, 4.0, -1.0],
    [0.1, 1.0, -1.0],
    [0.1, 2.0, -1.0],
    [0.1, 3.0, -1.0]
]
central_atom = ... # C, N or O, used later in the script
acsf = ACSF(
    species=species,
    rcut=rcut,
    g2_params=g2_params,
    g4_params=g4_params
)
```

Pickled file is a dictionary with keys `grid`, `y` and `x`, for the spectral grid, output spectra and input ACSF vectors, respectively. There are also keys `names` for the `qm9id_atom-index` and `origin_smiles` for the SMILES string (molecule) of origin (useful for later if we want to e.g. train on small molecules and predict on big ones). Note that any O (C) spectra with any intensity value greater than 5 (10) in the first 10 (35) grid points was discarded (these are generally un-physical, or at the very least, extreme outliers).


# XANES database 22 June 2022

**Filename:** `XANES-220622-C-N-O.pkl`

Calculations run on the Brookhaven National Laboratory Institutional Cluster: QM9 database Carbon, Nitrogen and Oxygen XANES calculated using FEFF.

To read the data, you can use `pickle`:

```python
import pickle
data = pickle.load(open("XANES-220622-C-N-O.pkl", "rb"))
```

## Data summary
The data is contained in simple serializable form: a Python dictionary. It is organized as follows.

- `data.keys()` are the QM9 ID's e.g. "787"
- `data[QM9_ID].keys()` are the various data for each QM9 id
    - `data[QM9_ID]["smiles"]`: the SMILES string of the molecule
    - `data[QM9_ID]["canon_smiles"]`: the canonical SMILES string of the molecule
    - `data[QM9_ID]["other"]`: other data corresponding to the molecule. These properties are described in the next section and are probably not going to be very important for our XAS work.
    - `data[QM9_ID]["zwitter"]`: if True, this molecule is a zwitter-ionic species. These molecules should probably be avoided in our datasets.
    - `data[QM9_ID]["molecule"]`: the serialized version of the `pymatgen.core.structure.Molecule` object created using the `monty.json.MSONable` library. A `Molecule` can be initialized via `Molecule.from_dict(data[QM9_ID]["molecule"])`.
    - `data[QM9_ID]["xanes"]`: the calculated FEFF XANES data. This is also a dictionary: the keys are `{site}_{absorbing_atom}` strings.
        - `data[QM9_ID]["xanes"][KEY]["feff.inp"]`: the verbatim FEFF input file used in the calculation.
        - `data[QM9_ID]["xanes"][KEY]["feff.out"]`: the verbatim FEFF output file used in the calculation.
        - `data[QM9_ID]["xanes"][KEY]["spectrum_metadata"]`: the verbatim comment lines in `xmu.dat`.
        - `data[QM9_ID]["xanes"][KEY]["spectrum"]`: the `xmu.dat` file read via `np.loadtxt(..., comment="#")`. The important columns are `0` and `3`, which are the energy grid and XANES intensities, respectively.

**Note**: in order to be useful for ML purposes, all spectra must be interpolated onto a common energy grid. The energy grids for each of the site spectra are not necessarily the same (in fact, they are almost always different). The default grids we use are

```python
N = 200
grids = {
    "O": np.linspace(528, 582, N),
    "N": np.linspace(395, 449, N),
    "C": np.linspace(275, 329, N)
}
```

**Note**: not every FEFF calculation completed. These situations should end up with the `spectrum` and `spectrum_metadata` as `None`. In situations where not every calculation completes for some molecule, that molecular signal cannot be completed and thus that data point should not be used in a database where full molecular signals are considered.


## QM9 `other` properties

In order:

- "A" (GHz) rotational constant
- "B" (GHz) rotational constant
- "C" (GHz) rotational constant
- "mu" (Debeye) dipole moment
- "alpha" (a0^3) isotropic polarizability
- "HOMO energy" (Ha)
- "LUMO energy" (Ha)
- "E gap" (Ha) 8-9 (might be uHa?)
- "<R^2>" (a0^2) electronic spatial extent
- "zpve" (Ha) zero-point vibrational energy
- "U0" (Ha) internal energy at 0 K
- "U" (Ha) internal energy at 198.15 K
- "H" (Ha) enthalpy at 298.15 K
- "G" (Ha) gibbs free energy at 298.15 K
- "Cv" (cal/molK) heat capacity at 298.15 K
